# frozen_string_literal: true

module OsvDepScanner
  module Osv
    # OSV vulnerability records have no single guaranteed severity field.
    # This applies a pragmatic precedence order across the shapes that
    # actually show up in real records, rather than parsing CVSS vectors
    # (a real CVSS scorer is out of scope for v1 — see README limitations).
    module Severity
      LEVELS = %i[unknown low medium high critical].freeze

      STRING_TO_LEVEL = {
        "LOW" => :low,
        "MODERATE" => :medium, # GHSA's word for "medium"
        "MEDIUM" => :medium,
        "HIGH" => :high,
        "CRITICAL" => :critical
      }.freeze

      CVSS_TYPES = %w[CVSS_V2 CVSS_V3 CVSS_V4].freeze

      def self.derive(vuln, package_name: nil)
        return :unknown unless vuln

        from_database_specific(vuln) ||
          from_affected_ecosystem_specific(vuln, package_name) ||
          from_cvss_presence(vuln) ||
          :unknown
      end

      def self.rank(level)
        LEVELS.index(level) || 0
      end

      def self.highest(levels)
        levels.max_by { |level| rank(level) } || :unknown
      end

      def self.from_database_specific(vuln)
        normalize(vuln.dig("database_specific", "severity"))
      end

      def self.from_affected_ecosystem_specific(vuln, package_name)
        levels = Array(vuln["affected"]).filter_map do |affected|
          next if package_name && affected.dig("package", "name") != package_name

          normalize(affected.dig("ecosystem_specific", "severity"))
        end
        levels.empty? ? nil : highest(levels)
      end

      def self.from_cvss_presence(vuln)
        :medium if Array(vuln["severity"]).any? { |entry| CVSS_TYPES.include?(entry["type"]) }
      end

      def self.normalize(value)
        return nil unless value.is_a?(String)

        STRING_TO_LEVEL[value.strip.upcase]
      end
    end
  end
end
