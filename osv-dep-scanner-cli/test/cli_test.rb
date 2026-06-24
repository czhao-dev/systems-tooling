# frozen_string_literal: true

require_relative "test_helper"

class CliExitCodeTest < Minitest::Test
  def test_clean_report_exits_zero
    assert_equal 0, OsvDepScanner::Cli.exit_code_for(report(severity: nil), "low")
  end

  def test_scan_errors_always_exit_five_regardless_of_severity
    report = report(severity: :critical, scan_errors: ["boom"])
    assert_equal 5, OsvDepScanner::Cli.exit_code_for(report, "low")
  end

  def test_fail_on_none_always_exits_zero
    assert_equal 0, OsvDepScanner::Cli.exit_code_for(report(severity: :critical), "none")
  end

  def test_exit_code_scales_with_worst_severity
    assert_equal 1, OsvDepScanner::Cli.exit_code_for(report(severity: :low), "low")
    assert_equal 2, OsvDepScanner::Cli.exit_code_for(report(severity: :medium), "low")
    assert_equal 3, OsvDepScanner::Cli.exit_code_for(report(severity: :high), "low")
    assert_equal 4, OsvDepScanner::Cli.exit_code_for(report(severity: :critical), "low")
  end

  def test_fail_on_threshold_suppresses_lower_severities
    assert_equal 0, OsvDepScanner::Cli.exit_code_for(report(severity: :low), "high")
    assert_equal 0, OsvDepScanner::Cli.exit_code_for(report(severity: :medium), "high")
    assert_equal 3, OsvDepScanner::Cli.exit_code_for(report(severity: :high), "high")
  end

  def test_unknown_severity_finding_still_fails_at_default_threshold
    assert_equal 1, OsvDepScanner::Cli.exit_code_for(report(severity: :unknown), "low")
  end

  private

  def report(severity:, scan_errors: [])
    findings = if severity
                 [OsvDepScanner::Finding.new(vuln_id: "X", summary: nil, severity: severity,
                                             affected_dependencies: [], references: [])]
               else
                 []
               end
    OsvDepScanner::ScanReport.new(findings: findings, manifest_paths: ["x"], dependency_count: 1,
                                  scan_errors: scan_errors, ecosystems: [:npm])
  end
end

class CliOptionParsingTest < Minitest::Test
  def test_raises_usage_error_for_unknown_ecosystem
    error = assert_raises(OsvDepScanner::Cli::UsageError) do
      OsvDepScanner::Cli.parse_options(["--ecosystems", "npm,cobol"])
    end
    assert_match(/cobol/, error.message)
  end

  def test_raises_usage_error_for_invalid_format
    assert_raises(OsvDepScanner::Cli::UsageError) do
      OsvDepScanner::Cli.parse_options(["--format", "xml"])
    end
  end

  def test_defaults_are_sane
    options = OsvDepScanner::Cli.parse_options([])

    assert_equal ".", options[:path]
    assert_equal "text", options[:format]
    assert_equal "low", options[:fail_on]
    assert_equal 60, options[:timeout]
  end

  def test_parses_ecosystems_list_into_symbols
    options = OsvDepScanner::Cli.parse_options(["--ecosystems", "npm, gomod"])
    assert_equal %i[npm gomod], options[:ecosystems]
  end
end
