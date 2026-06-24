# frozen_string_literal: true

module OsvDepScanner
  # Orchestrates discover -> batch query -> hydrate -> aggregate. Takes an
  # osv.Client-shaped object (duck type: #query_batch and #get_vuln) so tests
  # can inject a fake with no HTTP involved at all.
  class Scan
    DEFAULT_ECOSYSTEMS = %i[npm pypi cargo gomod].freeze
    MAX_CONCURRENCY = 8

    OSV_ECOSYSTEMS = { npm: "npm", pypi: "PyPI", cargo: "crates.io", gomod: "Go" }.freeze

    def initialize(client:, ecosystems: DEFAULT_ECOSYSTEMS)
      @client = client
      @ecosystems = ecosystems
    end

    def run(path)
      discovery = Manifest.discover(path, ecosystems: @ecosystems)

      return empty_report(["no supported manifests found under #{path}"]) if discovery.manifest_paths.empty?

      vuln_ids_by_dependency = @client.query_batch(packages_for(discovery.dependencies))
      vulns_by_id = hydrate(vuln_ids_by_dependency.flatten.uniq)

      findings = Aggregate.build(dependencies: discovery.dependencies, vuln_ids_by_dependency: vuln_ids_by_dependency,
                                 vulns_by_id: vulns_by_id)

      ScanReport.new(findings: findings, manifest_paths: discovery.manifest_paths,
                     dependency_count: discovery.dependencies.size, scan_errors: discovery.errors,
                     ecosystems: @ecosystems)
    rescue Osv::ApiError => e
      empty_report(["OSV API error: #{e.message}"])
    end

    private

    def packages_for(dependencies)
      dependencies.map do |dep|
        { name: dep.name, ecosystem: OSV_ECOSYSTEMS.fetch(dep.ecosystem), version: dep.version }
      end
    end

    def hydrate(ids)
      results = {}
      return results if ids.empty?

      mutex = Mutex.new
      queue = Queue.new
      ids.each { |id| queue << id }

      workers = Array.new([MAX_CONCURRENCY, ids.size].min) do
        Thread.new do
          loop do
            id = begin
              queue.pop(true)
            rescue ThreadError
              break
            end
            vuln = @client.get_vuln(id)
            mutex.synchronize { results[id] = vuln }
          end
        end
      end
      workers.each(&:join)

      results
    end

    def empty_report(errors)
      ScanReport.new(findings: [], manifest_paths: [], dependency_count: 0, scan_errors: errors,
                     ecosystems: @ecosystems)
    end
  end
end
