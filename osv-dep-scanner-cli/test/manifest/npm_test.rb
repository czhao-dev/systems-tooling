# frozen_string_literal: true

require_relative "../test_helper"

class NpmManifestTest < Minitest::Test
  def test_parses_v3_lockfile_packages_map
    content = File.read(fixture_path("npm", "v3-lockfile.json"))
    deps = OsvDepScanner::Manifest::Npm.parse(content)

    assert_includes deps, { name: "lodash", version: "4.17.15" }
    assert_includes deps, { name: "@scope/pkg", version: "2.0.0" }
    refute_includes deps.map { |d| d[:name] }, "demo" # root project entry excluded
  end

  def test_rejects_lockfile_without_v2_v3_packages_map
    content = File.read(fixture_path("npm", "v1-lockfile.json"))

    assert_raises(OsvDepScanner::Manifest::ParseError) do
      OsvDepScanner::Manifest::Npm.parse(content)
    end
  end

  def test_derives_scoped_name_from_nested_path
    name = OsvDepScanner::Manifest::Npm.derive_name("node_modules/foo/node_modules/@scope/bar")
    assert_equal "@scope/bar", name
  end
end
