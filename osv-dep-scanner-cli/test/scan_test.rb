# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"

class FakeOsvClient
  def initialize(vulns_by_package: {}, vulns_by_id: {}, raise_on_query: nil)
    @vulns_by_package = vulns_by_package
    @vulns_by_id = vulns_by_id
    @raise_on_query = raise_on_query
  end

  def query_batch(packages)
    raise @raise_on_query if @raise_on_query

    packages.map { |pkg| @vulns_by_package.fetch(pkg[:name], []) }
  end

  def get_vuln(id)
    @vulns_by_id[id]
  end
end

class ScanTest < Minitest::Test
  def test_reports_no_manifests_found_as_a_scan_error
    Dir.mktmpdir do |dir|
      report = OsvDepScanner::Scan.new(client: FakeOsvClient.new).run(dir)

      assert(report.scan_errors.any? { |err| err.include?("no supported manifests found") })
      assert report.clean?
    end
  end

  def test_finds_and_aggregates_a_known_vulnerability
    Dir.mktmpdir do |dir|
      write(dir, "package-lock.json", npm_lockfile_with("lodash", "4.17.15"))

      client = FakeOsvClient.new(
        vulns_by_package: { "lodash" => ["GHSA-1"] },
        vulns_by_id: { "GHSA-1" => { "summary" => "proto pollution", "database_specific" => { "severity" => "HIGH" } } }
      )

      report = OsvDepScanner::Scan.new(client: client).run(dir)

      assert_equal 1, report.findings.size
      finding = report.findings.first
      assert_equal "GHSA-1", finding.vuln_id
      assert_equal :high, finding.severity
      assert_equal 1, finding.affected_dependencies.size
      assert_equal :high, report.worst_severity
    end
  end

  def test_deduplicates_one_vuln_id_across_multiple_affected_dependencies
    Dir.mktmpdir do |dir|
      write(dir, "package-lock.json", npm_lockfile_with("lodash", "4.17.15"))
      write(dir, "nested/requirements.txt", "lodash==4.17.15\n") # not a real ecosystem match, just padding

      client = FakeOsvClient.new(
        vulns_by_package: { "lodash" => ["GHSA-1"] },
        vulns_by_id: { "GHSA-1" => { "summary" => "x", "database_specific" => { "severity" => "LOW" } } }
      )

      report = OsvDepScanner::Scan.new(client: client).run(dir)

      assert_equal 1, report.findings.size
    end
  end

  def test_continues_after_a_partial_manifest_parse_failure
    Dir.mktmpdir do |dir|
      write(dir, "package-lock.json", "not valid json")
      write(dir, "requirements.txt", "flask==1.0.0\n")

      report = OsvDepScanner::Scan.new(client: FakeOsvClient.new).run(dir)

      assert_equal 1, report.scan_errors.size
      assert_equal 1, report.dependency_count
      assert report.clean?
    end
  end

  def test_wraps_osv_api_errors_as_a_scan_error
    Dir.mktmpdir do |dir|
      write(dir, "requirements.txt", "flask==1.0.0\n")
      client = FakeOsvClient.new(raise_on_query: OsvDepScanner::Osv::ApiError.new("boom"))

      report = OsvDepScanner::Scan.new(client: client).run(dir)

      assert(report.scan_errors.any? { |err| err.include?("boom") })
    end
  end

  private

  def npm_lockfile_with(name, version)
    { packages: { "node_modules/#{name}" => { version: version } } }.to_json
  end

  def write(dir, relative_path, content)
    full_path = File.join(dir, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end
end
