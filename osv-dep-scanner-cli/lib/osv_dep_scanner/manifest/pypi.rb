# frozen_string_literal: true

module OsvDepScanner
  module Manifest
    # Parses requirements.txt lines pinned with "==". Ranges (>=, ~=, etc.),
    # unpinned names, extras ("pkg[extra]==1.0"), and -r/-e/--hash options are
    # intentionally skipped rather than guessed at (see README limitations).
    module Pypi
      LINE_PATTERN = /\A([A-Za-z0-9][A-Za-z0-9._-]*)\s*==\s*([^\s;#]+)/

      def self.parse(content)
        content.each_line.filter_map do |raw_line|
          line = raw_line.strip
          next if line.empty? || line.start_with?("#", "-")

          match = LINE_PATTERN.match(line)
          next unless match

          { name: match[1], version: match[2] }
        end
      end
    end
  end
end
