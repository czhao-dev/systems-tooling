# frozen_string_literal: true

require_relative "test_helper"

class AggregateTest < Minitest::Test
  def test_builds_one_finding_per_unique_vuln_id_across_dependencies
    dep_a = OsvDepScanner::Manifest::Dependency.new(ecosystem: :npm, name: "lodash", version: "4.17.15",
                                                    manifest_path: "a/package-lock.json")
    dep_b = OsvDepScanner::Manifest::Dependency.new(ecosystem: :npm, name: "lodash", version: "4.17.15",
                                                    manifest_path: "b/package-lock.json")
    vuln = { "summary" => "proto pollution", "database_specific" => { "severity" => "HIGH" },
             "references" => [{ "url" => "https://example.com/a" }] }

    findings = OsvDepScanner::Aggregate.build(
      dependencies: [dep_a, dep_b],
      vuln_ids_by_dependency: [["GHSA-1"], ["GHSA-1"]],
      vulns_by_id: { "GHSA-1" => vuln }
    )

    assert_equal 1, findings.size
    finding = findings.first
    assert_equal "GHSA-1", finding.vuln_id
    assert_equal :high, finding.severity
    assert_equal [dep_a, dep_b], finding.affected_dependencies
    assert_equal ["https://example.com/a"], finding.references
  end

  def test_handles_a_vuln_id_with_no_hydrated_details
    dep = OsvDepScanner::Manifest::Dependency.new(ecosystem: :npm, name: "lodash", version: "4.17.15",
                                                  manifest_path: "package-lock.json")

    findings = OsvDepScanner::Aggregate.build(
      dependencies: [dep],
      vuln_ids_by_dependency: [["GHSA-missing"]],
      vulns_by_id: {}
    )

    finding = findings.first
    assert_nil finding.summary
    assert_equal :unknown, finding.severity
    assert_equal [], finding.references
  end

  def test_scan_report_worst_severity_and_clean
    report = OsvDepScanner::ScanReport.new(findings: [], manifest_paths: [], dependency_count: 0, scan_errors: [],
                                           ecosystems: [:npm])
    assert report.clean?
    assert_equal :unknown, report.worst_severity
  end
end
