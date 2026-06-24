# frozen_string_literal: true

module OsvDepScanner
  module Manifest
    # Parses go.mod "require" lines, both single-line and block form.
    # "replace"/"exclude" directives and the module/go directives are ignored.
    module Gomod
      SINGLE_LINE = /\Arequire\s+(\S+)\s+(\S+)/
      BLOCK_LINE = /\A(\S+)\s+(\S+)/

      def self.parse(content)
        dependencies = []
        in_require_block = false

        content.each_line do |raw_line|
          line = strip_comment(raw_line)
          next if line.empty?

          if line.start_with?("require (")
            in_require_block = true
            next
          end

          if in_require_block
            in_require_block = block_still_open?(line, dependencies)
            next
          end

          match = SINGLE_LINE.match(line)
          dependencies << { name: match[1], version: match[2] } if match
        end

        dependencies
      end

      # Records a dependency from a require-block line; returns false once
      # the closing ")" is seen so the caller can stop treating lines as block content.
      def self.block_still_open?(line, dependencies)
        return false if line == ")"

        match = BLOCK_LINE.match(line)
        dependencies << { name: match[1], version: match[2] } if match
        true
      end

      def self.strip_comment(raw_line)
        raw_line.split("//").first.to_s.strip
      end
    end
  end
end
