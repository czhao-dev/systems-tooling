# frozen_string_literal: true

require_relative "../test_helper"

class GomodManifestTest < Minitest::Test
  def test_parses_block_and_single_line_requires
    content = File.read(fixture_path("gomod", "go.mod"))
    deps = OsvDepScanner::Manifest::Gomod.parse(content)

    assert_equal [
      { name: "github.com/gorilla/mux", version: "v1.8.0" },
      { name: "golang.org/x/text", version: "v0.3.0" },
      { name: "golang.org/x/sys", version: "v0.1.0" }
    ], deps
  end

  def test_ignores_replace_and_module_directives
    content = <<~GOMOD
      module example.com/foo

      replace example.com/foo/bar => ../bar
    GOMOD

    assert_equal [], OsvDepScanner::Manifest::Gomod.parse(content)
  end
end
