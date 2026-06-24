# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module OsvDepScanner
  module Osv
    class ApiError < StandardError
    end

    # Thin wrapper around OSV.dev's REST API. Talks only in plain
    # name/ecosystem/version and vuln-ID terms so it can be swapped for a
    # fake in orchestration tests, or pointed at a local server in its own
    # tests via base_url:.
    class Client
      DEFAULT_BASE_URL = "https://api.osv.dev"

      def initialize(base_url: DEFAULT_BASE_URL, open_timeout: 10, read_timeout: 10)
        @base_url = base_url
        @open_timeout = open_timeout
        @read_timeout = read_timeout
      end

      # packages: [{name:, ecosystem:, version:}, ...]
      # returns: [[vuln_id, ...], ...] aligned by index with the input packages
      def query_batch(packages)
        return [] if packages.empty?

        body = { queries: packages.map { |pkg| query_for(pkg) } }
        response = post("/v1/querybatch", body)
        Array(response["results"]).map { |result| Array(result["vulns"]).map { |v| v["id"] } }
      end

      def get_vuln(id)
        get("/v1/vulns/#{URI.encode_www_form_component(id)}")
      end

      private

      def query_for(pkg)
        { version: pkg[:version], package: { name: pkg[:name], ecosystem: pkg[:ecosystem] } }
      end

      def post(path, body)
        uri = URI.join(@base_url, path)
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request.body = body.to_json
        perform(uri, request)
      end

      def get(path)
        uri = URI.join(@base_url, path)
        perform(uri, Net::HTTP::Get.new(uri))
      end

      def perform(uri, request)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                                       open_timeout: @open_timeout,
                                                       read_timeout: @read_timeout) do |http|
          http.request(request)
        end
        raise ApiError, "#{request.method} #{uri} returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      rescue JSON::ParserError => e
        raise ApiError, "invalid JSON from #{uri}: #{e.message}"
      end
    end
  end
end
