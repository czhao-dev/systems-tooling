# frozen_string_literal: true

require_relative "../test_helper"
require "webrick"
require "json"

# Stands up a real local HTTP server with canned responses - the Ruby
# analogue of Go's httptest.NewServer - so the client's wire format is
# exercised without making any external network calls.
class OsvClientTest < Minitest::Test
  def setup
    @responses = {}
    @requests = []
    @server = WEBrick::HTTPServer.new(Port: 0, Logger: WEBrick::Log.new(File::NULL), AccessLog: [])
    @server.mount_proc("/") { |req, res| handle(req, res) }
    @thread = Thread.new { @server.start }
    sleep 0.01 until @server.status == :Running
    @client = OsvDepScanner::Osv::Client.new(base_url: "http://127.0.0.1:#{@server.config[:Port]}")
  end

  def teardown
    @server.shutdown
    @thread.join
  end

  def test_query_batch_posts_packages_and_parses_vuln_ids
    stub("/v1/querybatch", body: { results: [{ vulns: [{ id: "GHSA-1" }] }, { vulns: [] }] }.to_json)

    result = @client.query_batch([
                                   { name: "lodash", ecosystem: "npm", version: "4.17.15" },
                                   { name: "safe-pkg", ecosystem: "npm", version: "1.0.0" }
                                 ])

    assert_equal [["GHSA-1"], []], result
    sent = JSON.parse(@requests.first[:body])
    assert_equal "lodash", sent["queries"][0]["package"]["name"]
    assert_equal "npm", sent["queries"][0]["package"]["ecosystem"]
    assert_equal "4.17.15", sent["queries"][0]["version"]
  end

  def test_query_batch_returns_empty_array_for_no_packages_without_a_request
    assert_equal [], @client.query_batch([])
    assert_empty @requests
  end

  def test_get_vuln_fetches_by_id
    stub("/v1/vulns/GHSA-1", body: { id: "GHSA-1", summary: "test vuln" }.to_json)

    vuln = @client.get_vuln("GHSA-1")

    assert_equal "test vuln", vuln["summary"]
  end

  def test_raises_api_error_on_non_success_response
    stub("/v1/vulns/missing", status: 404, body: "not found")

    assert_raises(OsvDepScanner::Osv::ApiError) { @client.get_vuln("missing") }
  end

  def test_raises_api_error_on_malformed_json
    stub("/v1/vulns/bad", body: "not json")

    assert_raises(OsvDepScanner::Osv::ApiError) { @client.get_vuln("bad") }
  end

  private

  def stub(path, body:, status: 200)
    @responses[path] = { status: status, body: body }
  end

  def handle(req, res)
    @requests << { method: req.request_method, path: req.path, body: req.body }
    canned = @responses[req.path]
    if canned
      res.status = canned[:status]
      res.content_type = "application/json"
      res.body = canned[:body]
    else
      res.status = 404
      res.body = "no stub for #{req.path}"
    end
  end
end
