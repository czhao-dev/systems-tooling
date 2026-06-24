# frozen_string_literal: true

require "json"

module OsvDepScanner
  module Manifest
    # Parses npm lockfile v2/v3's "packages" map. v1's nested "dependencies"
    # tree is intentionally unsupported (see README limitations).
    module Npm
      def self.parse(content)
        packages = packages_map(content)

        dependencies = {}
        packages.each do |pkg_path, info|
          dep = dependency_for(pkg_path, info)
          dependencies[[dep[:name], dep[:version]]] = dep if dep
        end
        dependencies.values
      end

      def self.packages_map(content)
        packages = JSON.parse(content)["packages"]
        unless packages.is_a?(Hash)
          raise OsvDepScanner::Manifest::ParseError,
                "unsupported package-lock.json format (no v2/v3 \"packages\" map found)"
        end

        packages
      end

      def self.dependency_for(pkg_path, info)
        return nil if pkg_path.to_s.empty? # the root project entry itself
        return nil unless info.is_a?(Hash)

        name = info["name"] || derive_name(pkg_path)
        version = info["version"]
        return nil if name.nil? || version.nil?

        { name: name, version: version }
      end

      # v3 entries are keyed by install path (e.g. "node_modules/@scope/name"
      # or nested "node_modules/foo/node_modules/bar") and only carry an
      # explicit "name" field when it differs from what the path implies.
      def self.derive_name(pkg_path)
        pkg_path.split("node_modules/").last
      end
    end
  end
end
