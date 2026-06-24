# frozen_string_literal: true

require_relative "../test_helper"

class SeverityTest < Minitest::Test
  def test_uses_database_specific_severity_first
    vuln = { "database_specific" => { "severity" => "HIGH" } }
    assert_equal :high, OsvDepScanner::Osv::Severity.derive(vuln)
  end

  def test_maps_ghsa_moderate_to_medium
    vuln = { "database_specific" => { "severity" => "MODERATE" } }
    assert_equal :medium, OsvDepScanner::Osv::Severity.derive(vuln)
  end

  def test_falls_back_to_affected_ecosystem_specific
    vuln = { "affected" => [
      { "package" => { "name" => "lodash" }, "ecosystem_specific" => { "severity" => "HIGH" } }
    ] }
    assert_equal :high, OsvDepScanner::Osv::Severity.derive(vuln, package_name: "lodash")
  end

  def test_takes_highest_among_multiple_affected_entries
    vuln = { "affected" => [
      { "package" => { "name" => "lodash" }, "ecosystem_specific" => { "severity" => "LOW" } },
      { "package" => { "name" => "lodash" }, "ecosystem_specific" => { "severity" => "CRITICAL" } }
    ] }
    assert_equal :critical, OsvDepScanner::Osv::Severity.derive(vuln, package_name: "lodash")
  end

  def test_ignores_affected_entries_for_other_packages
    vuln = { "affected" => [
      { "package" => { "name" => "other-pkg" }, "ecosystem_specific" => { "severity" => "CRITICAL" } }
    ] }
    assert_equal :unknown, OsvDepScanner::Osv::Severity.derive(vuln, package_name: "lodash")
  end

  def test_falls_back_to_medium_when_only_a_cvss_vector_is_present
    vuln = { "severity" => [{ "type" => "CVSS_V3", "score" => "CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:H" }] }
    assert_equal :medium, OsvDepScanner::Osv::Severity.derive(vuln)
  end

  def test_unknown_when_nothing_present
    assert_equal :unknown, OsvDepScanner::Osv::Severity.derive({})
  end

  def test_unknown_for_nil_vuln
    assert_equal :unknown, OsvDepScanner::Osv::Severity.derive(nil)
  end

  def test_database_specific_takes_precedence_over_cvss
    vuln = {
      "severity" => [{ "type" => "CVSS_V3", "score" => "x" }],
      "database_specific" => { "severity" => "LOW" }
    }
    assert_equal :low, OsvDepScanner::Osv::Severity.derive(vuln)
  end

  def test_highest_picks_max_rank
    assert_equal :critical, OsvDepScanner::Osv::Severity.highest(%i[low critical medium])
  end

  def test_highest_defaults_to_unknown_for_empty
    assert_equal :unknown, OsvDepScanner::Osv::Severity.highest([])
  end
end
