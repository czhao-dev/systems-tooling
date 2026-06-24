# frozen_string_literal: true

require_relative "test_helper"
require "json"

class ReportFormatterTest < Minitest::Test
  def setup
    dep = OsvDepScanner::Manifest::Dependency.new(ecosystem: :npm, name: "lodash", version: "4.17.15",
                                                  manifest_path: "package-lock.json")
    findings = [
      OsvDepScanner::Finding.new(vuln_id: "GHSA-1", summary: "proto pollution", severity: :high,
                                 affected_dependencies: [dep], references: ["https://example.com"]),
      OsvDepScanner::Finding.new(vuln_id: "GHSA-2", summary: "minor issue", severity: :low,
                                 affected_dependencies: [dep], references: [])
    ]
    @report = OsvDepScanner::ScanReport.new(findings: findings, manifest_paths: ["package-lock.json"],
                                            dependency_count: 1, scan_errors: [], ecosystems: [:npm])
  end

  def test_text_lists_findings_worst_severity_first
    output = OsvDepScanner::Report::Text.render(@report)

    assert_match(/Findings: 2/, output)
    assert_operator output.index("GHSA-1"), :<, output.index("GHSA-2")
    assert_match(/affects npm:lodash@4\.17\.15/, output)
  end

  def test_markdown_includes_summary_table_and_sections
    output = OsvDepScanner::Report::Markdown.render(@report)

    assert_match(/\| Manifests scanned \| Dependencies checked \| Findings \| Worst severity \|/, output)
    assert_match(/## GHSA-1 \(high\)/, output)
    assert_match(/## GHSA-2 \(low\)/, output)
  end

  def test_json_is_parseable_and_round_trips_findings
    parsed = JSON.parse(OsvDepScanner::Report::Json.render(@report))

    assert_equal 2, parsed["findings"].size
    assert_equal "high", parsed["summary"]["worst_severity"]
    first = parsed["findings"].find { |f| f["id"] == "GHSA-1" }
    assert_equal "lodash", first["affected"].first["name"]
  end

  def test_renders_scan_errors_when_present
    report = OsvDepScanner::ScanReport.new(findings: [], manifest_paths: [], dependency_count: 0,
                                           scan_errors: ["something broke"], ecosystems: [:npm])

    assert_match(/something broke/, OsvDepScanner::Report::Text.render(report))
    assert_match(/something broke/, OsvDepScanner::Report::Markdown.render(report))
  end
end
