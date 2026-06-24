# frozen_string_literal: true

require "optparse"
require "timeout"

module OsvDepScanner
  module Cli
    class UsageError < StandardError
    end

    FORMATTERS = { "text" => Report::Text, "markdown" => Report::Markdown, "json" => Report::Json }.freeze
    FAIL_ON_LEVELS = %w[none low medium high critical].freeze
    SEVERITY_RANK = { "unknown" => 0, "low" => 0, "medium" => 1, "high" => 2, "critical" => 3 }.freeze

    EXIT_SCAN_ERROR = 5
    EXIT_USAGE_ERROR = 64

    def self.run(argv)
      options = parse_options(argv)
      report = scan(options)
      output = FORMATTERS.fetch(options[:format]).render(report)
      write_output(output, options[:output])
      exit_code_for(report, options[:fail_on])
    rescue UsageError => e
      warn "osv-dep-scanner: #{e.message}"
      EXIT_USAGE_ERROR
    rescue Timeout::Error
      warn "osv-dep-scanner: scan timed out after #{options[:timeout]}s"
      EXIT_SCAN_ERROR
    end

    def self.scan(options)
      client = Osv::Client.new(base_url: options[:osv_base_url])
      scanner = Scan.new(client: client, ecosystems: options[:ecosystems])
      Timeout.timeout(options[:timeout]) { scanner.run(options[:path]) }
    end

    def self.exit_code_for(report, fail_on)
      return EXIT_SCAN_ERROR unless report.scan_errors.empty?
      return 0 if report.clean? || fail_on == "none"

      worst = report.worst_severity.to_s
      return 0 if SEVERITY_RANK.fetch(worst, 0) < SEVERITY_RANK.fetch(fail_on, 0)

      ScanReport::SEVERITY_EXIT_CODES.fetch(report.worst_severity, 1)
    end

    def self.write_output(content, path)
      if path
        File.write(path, "#{content}\n")
      else
        puts content
      end
    end

    def self.parse_options(argv)
      options = default_options
      build_parser(options).parse!(argv)
      validate_ecosystems!(options[:ecosystems])
      options
    rescue OptionParser::ParseError => e
      raise UsageError, e.message
    end

    def self.default_options
      {
        path: ".",
        ecosystems: Scan::DEFAULT_ECOSYSTEMS,
        format: "text",
        output: nil,
        fail_on: "low",
        timeout: 60,
        osv_base_url: Osv::Client::DEFAULT_BASE_URL
      }
    end

    def self.build_parser(options)
      OptionParser.new do |opts|
        opts.banner = "Usage: osv-dep-scanner [options]"
        add_scan_options(opts, options)
        add_output_options(opts, options)
        add_meta_options(opts)
      end
    end

    def self.add_scan_options(opts, options)
      opts.on("--path PATH", "Directory to scan (default \".\")") { |v| options[:path] = v }
      opts.on("--ecosystems LIST", "Comma-separated subset: npm,pypi,cargo,gomod (default: all)") do |v|
        options[:ecosystems] = v.split(",").map { |e| e.strip.to_sym }
      end
      opts.on("--timeout SECONDS", Integer, "Overall scan timeout in seconds (default 60)") do |v|
        options[:timeout] = v
      end
      opts.on("--osv-base-url URL", "Override the OSV API base URL") { |v| options[:osv_base_url] = v }
    end

    def self.add_output_options(opts, options)
      opts.on("--format FORMAT", FORMATTERS.keys, "Output format: #{FORMATTERS.keys.join('|')}") do |v|
        options[:format] = v
      end
      opts.on("--output PATH", "Write report to file instead of stdout") { |v| options[:output] = v }
      opts.on("--fail-on LEVEL", FAIL_ON_LEVELS,
              "Minimum severity that fails the run: #{FAIL_ON_LEVELS.join('|')} (default low)") do |v|
        options[:fail_on] = v
      end
    end

    def self.add_meta_options(opts)
      opts.on("--version", "Print version and exit") do
        puts OsvDepScanner::VERSION
        exit 0
      end
      opts.on("-h", "--help", "Show this help") do
        puts opts
        exit 0
      end
    end

    def self.validate_ecosystems!(ecosystems)
      invalid = ecosystems - Scan::DEFAULT_ECOSYSTEMS
      raise UsageError, "unknown ecosystems: #{invalid.join(', ')}" unless invalid.empty?
    end
  end
end
