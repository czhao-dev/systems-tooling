# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"

class ManifestDiscoverTest < Minitest::Test
  def test_discovers_and_parses_known_manifests_recursively
    Dir.mktmpdir do |dir|
      write(dir, "requirements.txt", "flask==1.0.0\n")
      write(dir, "sub/go.mod", "module x\n\nrequire golang.org/x/sys v0.1.0\n")

      result = OsvDepScanner::Manifest.discover(dir)

      assert_equal 2, result.manifest_paths.size
      assert_equal [], result.errors
      names = result.dependencies.map(&:name)
      assert_includes names, "flask"
      assert_includes names, "golang.org/x/sys"
    end
  end

  def test_skips_node_modules_and_other_noise_directories
    Dir.mktmpdir do |dir|
      write(dir, "node_modules/some-dep/package-lock.json", '{"packages":{}}')
      write(dir, "requirements.txt", "flask==1.0.0\n")

      result = OsvDepScanner::Manifest.discover(dir)

      assert_equal 1, result.manifest_paths.size
      assert_equal "requirements.txt", File.basename(result.manifest_paths.first)
    end
  end

  def test_restricts_to_requested_ecosystems
    Dir.mktmpdir do |dir|
      write(dir, "requirements.txt", "flask==1.0.0\n")
      write(dir, "go.mod", "module x\n\nrequire golang.org/x/sys v0.1.0\n")

      result = OsvDepScanner::Manifest.discover(dir, ecosystems: [:pypi])

      assert_equal 1, result.manifest_paths.size
      assert_equal [:pypi], result.dependencies.map(&:ecosystem).uniq
    end
  end

  def test_records_parse_errors_without_aborting_other_manifests
    Dir.mktmpdir do |dir|
      write(dir, "package-lock.json", "not valid json")
      write(dir, "requirements.txt", "flask==1.0.0\n")

      result = OsvDepScanner::Manifest.discover(dir)

      assert_equal 1, result.errors.size
      assert_match(/package-lock\.json/, result.errors.first)
      assert_equal ["flask"], result.dependencies.map(&:name)
    end
  end

  private

  def write(dir, relative_path, content)
    full_path = File.join(dir, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end
end
