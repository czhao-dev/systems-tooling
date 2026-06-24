# frozen_string_literal: true

module OsvDepScanner
  Finding = Struct.new(:vuln_id, :summary, :severity, :affected_dependencies, :references, keyword_init: true)

  class ScanReport
    # An :unknown-severity finding still maps to a non-zero exit (we did find
    # a real vulnerability, we just couldn't grade it) so it shares low's code.
    SEVERITY_EXIT_CODES = { unknown: 1, low: 1, medium: 2, high: 3, critical: 4 }.freeze

    attr_reader :findings, :manifest_paths, :dependency_count, :scan_errors, :ecosystems

    def initialize(findings:, manifest_paths:, dependency_count:, scan_errors:, ecosystems:)
      @findings = findings
      @manifest_paths = manifest_paths
      @dependency_count = dependency_count
      @scan_errors = scan_errors
      @ecosystems = ecosystems
    end

    def worst_severity
      return :unknown if findings.empty?

      Osv::Severity.highest(findings.map(&:severity))
    end

    def clean?
      findings.empty?
    end
  end

  # Builds one Finding per unique vulnerability ID, even when that ID affects
  # several manifest entries (e.g. a duplicated transitive npm dependency) -
  # the reverse index below ensures it's reported once, not once per hit.
  module Aggregate
    def self.build(dependencies:, vuln_ids_by_dependency:, vulns_by_id:)
      dependencies_by_vuln_id = Hash.new { |hash, key| hash[key] = [] }
      dependencies.each_with_index do |dep, index|
        Array(vuln_ids_by_dependency[index]).each { |id| dependencies_by_vuln_id[id] << dep }
      end

      dependencies_by_vuln_id.map do |vuln_id, deps|
        build_finding(vuln_id, deps, vulns_by_id[vuln_id])
      end
    end

    def self.build_finding(vuln_id, deps, vuln)
      severity = Osv::Severity.highest(deps.map { |dep| Osv::Severity.derive(vuln, package_name: dep.name) })
      Finding.new(
        vuln_id: vuln_id,
        summary: vuln && vuln["summary"],
        severity: severity,
        affected_dependencies: deps,
        references: vuln ? Array(vuln["references"]).filter_map { |ref| ref["url"] } : []
      )
    end
  end
end
