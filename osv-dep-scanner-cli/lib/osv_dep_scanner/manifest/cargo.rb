# frozen_string_literal: true

module OsvDepScanner
  module Manifest
    # Hand-rolled line parser for Cargo.lock instead of a full TOML library:
    # Cargo.lock only ever contains flat [[package]] blocks with simple
    # key = "value" pairs, never nested tables or multiline strings.
    module Cargo
      FIELD_PATTERN = /\A(name|version)\s*=\s*"([^"]*)"\z/

      def self.parse(content)
        packages = []
        current = nil

        content.each_line do |raw_line|
          line = raw_line.strip
          if line == "[[package]]"
            packages << current if current
            current = {}
          else
            apply_field(current, line)
          end
        end
        packages << current if current

        packages.select { |pkg| complete?(pkg) }
      end

      def self.apply_field(current, line)
        return unless current

        match = FIELD_PATTERN.match(line)
        current[match[1].to_sym] = match[2] if match
      end

      def self.complete?(pkg)
        pkg[:name] && pkg[:version]
      end
    end
  end
end
