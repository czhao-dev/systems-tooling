# frozen_string_literal: true

module OsvDepScanner
  module Report
    module Text
      def self.render(report)
        lines = header(report)
        sorted_findings(report).each { |finding| lines.concat(finding_lines(finding)) }
        lines.concat(error_lines(report))
        lines.join("\n")
      end

      def self.header(report)
        [
          "Dependency Vulnerability Scan",
          "=============================",
          "Manifests scanned: #{report.manifest_paths.size}",
          "Dependencies checked: #{report.dependency_count}",
          "Findings: #{report.findings.size}",
          "Worst severity: #{report.worst_severity}",
          ""
        ]
      end

      def self.sorted_findings(report)
        report.findings.sort_by { |finding| -Osv::Severity.rank(finding.severity) }
      end

      def self.finding_lines(finding)
        lines = ["[#{finding.severity.to_s.upcase}] #{finding.vuln_id}"]
        lines << "  #{finding.summary}" if finding.summary
        finding.affected_dependencies.each do |dep|
          lines << "  affects #{dep.ecosystem}:#{dep.name}@#{dep.version} (#{dep.manifest_path})"
        end
        lines << ""
        lines
      end

      def self.error_lines(report)
        return [] if report.scan_errors.empty?

        ["Scan errors:"] + report.scan_errors.map { |err| "  - #{err}" }
      end
    end
  end
end
