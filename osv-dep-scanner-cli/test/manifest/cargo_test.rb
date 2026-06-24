# frozen_string_literal: true

require_relative "../test_helper"

class CargoManifestTest < Minitest::Test
  def test_parses_package_blocks
    content = File.read(fixture_path("cargo", "Cargo.lock"))
    deps = OsvDepScanner::Manifest::Cargo.parse(content)

    assert_equal [{ name: "libc", version: "0.2.0" }, { name: "time", version: "0.1.42" }], deps
  end

  def test_ignores_top_level_fields_outside_any_package_block
    content = <<~TOML
      version = 3

      [[package]]
      name = "onlypkg"
      version = "1.0.0"
    TOML

    assert_equal [{ name: "onlypkg", version: "1.0.0" }], OsvDepScanner::Manifest::Cargo.parse(content)
  end

  def test_skips_package_blocks_missing_a_version
    content = <<~TOML
      [[package]]
      name = "nameonly"
    TOML

    assert_equal [], OsvDepScanner::Manifest::Cargo.parse(content)
  end
end
