# frozen_string_literal: true

require_relative "../test_helper"

class PypiManifestTest < Minitest::Test
  def test_parses_pinned_versions_only
    content = File.read(fixture_path("pypi", "requirements.txt"))
    deps = OsvDepScanner::Manifest::Pypi.parse(content)

    assert_equal [{ name: "flask", version: "1.0.0" }, { name: "django", version: "3.2.1" }], deps
  end

  def test_skips_ranges_options_comments_and_extras
    content = <<~REQS
      requests>=2.0
      # comment
      -e .
      numpy[extra]==1.21.0
    REQS

    assert_equal [], OsvDepScanner::Manifest::Pypi.parse(content)
  end
end
