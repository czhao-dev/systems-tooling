# frozen_string_literal: true

module OsvDepScanner
  module Report
    module Markdown
      def self.render(report)
        lines = header(report)
        sorted_findings(report).each { |finding| lines.concat(finding_lines(finding)) }
        lines.concat(error_lines(report))
        lines.join("\n")
      end

      def self.header(report)
        [
          "# Dependency Vulnerability Scan",
          "",
          "| Manifests scanned | Dependencies checked | Findings | Worst severity |",
          "|---|---|---|---|",
          "| #{report.manifest_paths.size} | #{report.dependency_count} | #{report.findings.size} | " \
          "#{report.worst_severity} |",
          ""
        ]
      end

      def self.sorted_findings(report)
        report.findings.sort_by { |finding| -Osv::Severity.rank(finding.severity) }
      end

      def self.finding_lines(finding)
        lines = ["## #{finding.vuln_id} (#{finding.severity})", "", finding.summary.to_s, "", "Affected:"]
        finding.affected_dependencies.each do |dep|
          lines << "- `#{dep.ecosystem}:#{dep.name}@#{dep.version}` (#{dep.manifest_path})"
        end
        lines.concat(reference_lines(finding))
        lines << ""
        lines
      end

      def self.reference_lines(finding)
        return [] if finding.references.empty?

        ["", "References:"] + finding.references.map { |ref| "- #{ref}" }
      end

      def self.error_lines(report)
        return [] if report.scan_errors.empty?

        ["## Scan errors", ""] + report.scan_errors.map { |err| "- #{err}" }
      end
    end
  end
end
