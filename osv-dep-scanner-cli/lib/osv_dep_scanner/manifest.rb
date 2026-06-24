# frozen_string_literal: true

require "find"
require_relative "manifest/npm"
require_relative "manifest/pypi"
require_relative "manifest/cargo"
require_relative "manifest/gomod"

module OsvDepScanner
  module Manifest
    Dependency = Struct.new(:ecosystem, :name, :version, :manifest_path, keyword_init: true)
    Result = Struct.new(:dependencies, :manifest_paths, :errors, keyword_init: true)
    class ParseError < StandardError
    end

    MANIFEST_FILENAMES = {
      "package-lock.json" => :npm,
      "requirements.txt" => :pypi,
      "Cargo.lock" => :cargo,
      "go.mod" => :gomod
    }.freeze

    # Directories that are never worth descending into: they hold installed/
    # vendored/build output, not the manifests that describe it.
    SKIP_DIRS = %w[.git node_modules vendor target dist build .bundle].freeze

    PARSERS = {
      npm: Npm,
      pypi: Pypi,
      cargo: Cargo,
      gomod: Gomod
    }.freeze

    def self.discover(root, ecosystems: MANIFEST_FILENAMES.values.uniq)
      dependencies = []
      manifest_paths = []
      errors = []

      each_manifest_file(root) do |path, ecosystem|
        next unless ecosystems.include?(ecosystem)

        manifest_paths << path
        begin
          parsed = PARSERS.fetch(ecosystem).parse(File.read(path))
          parsed.each do |dep|
            dependencies << Dependency.new(ecosystem: ecosystem, name: dep[:name], version: dep[:version],
                                           manifest_path: path)
          end
        rescue StandardError => e
          errors << "#{path}: #{e.message}"
        end
      end

      Result.new(dependencies: dependencies, manifest_paths: manifest_paths, errors: errors)
    end

    def self.each_manifest_file(root)
      Find.find(root) do |path|
        if File.directory?(path)
          Find.prune if path != root && SKIP_DIRS.include?(File.basename(path))
          next
        end

        ecosystem = MANIFEST_FILENAMES[File.basename(path)]
        yield(path, ecosystem) if ecosystem
      end
    end
  end
end
