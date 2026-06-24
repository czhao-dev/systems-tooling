# frozen_string_literal: true

require "json"

module OsvDepScanner
  module Report
    module Json
      def self.render(report)
        JSON.pretty_generate(
          summary: {
            manifests_scanned: report.manifest_paths,
            dependency_count: report.dependency_count,
            ecosystems: report.ecosystems,
            worst_severity: report.worst_severity,
            scan_errors: report.scan_errors
          },
          findings: report.findings.map { |finding| finding_hash(finding) }
        )
      end

      def self.finding_hash(finding)
        {
          id: finding.vuln_id,
          severity: finding.severity,
          summary: finding.summary,
          references: finding.references,
          affected: finding.affected_dependencies.map { |dep| dependency_hash(dep) }
        }
      end

      def self.dependency_hash(dep)
        { ecosystem: dep.ecosystem, name: dep.name, version: dep.version, manifest: dep.manifest_path }
      end
    end
  end
end
