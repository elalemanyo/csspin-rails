# frozen_string_literal: true

require_relative "../../test_helper"
require "net/http"

class FakeHTTP
  def initialize(responses)
    @responses = Array(responses)
    @call_index = 0
  end

  def start
    yield self
  end

  def get(_uri)
    response = @responses[@call_index] || @responses.last
    @call_index += 1
    response
  end
end

class TestableDownloader < Csspin::HTTP::Downloader
  attr_writer :http_override

  private

  def build_http(_uri)
    @http_override
  end
end

class CsspinHttpDownloaderTest < Minitest::Test
  def test_returns_ok_for_successful_css_response
    response = build_response(Net::HTTPOK, "200", "/* css */", "text/css")
    downloader = build_downloader([response])

    result = downloader.get("https://cdn.jsdelivr.net/npm/trix/dist/trix.css")

    assert result[:ok]
    assert_equal "/* css */", result[:body]
  end

  def test_accepts_text_plain_content_type
    response = build_response(Net::HTTPOK, "200", "/* css */", "text/plain; charset=utf-8")
    downloader = build_downloader([response])

    result = downloader.get("https://cdn.jsdelivr.net/npm/trix/dist/trix.css")

    assert result[:ok]
  end

  def test_accepts_json_content_type_when_explicitly_allowed
    response = build_response(Net::HTTPOK, "200", '{"name":"trix"}', "application/json; charset=utf-8")
    downloader = build_downloader([response])

    result = downloader.get(
      "https://data.jsdelivr.com/v1/packages/npm/trix",
      allowed_content_types: ["application/json"]
    )

    assert result[:ok]
    assert_equal '{"name":"trix"}', result[:body]
  end

  def test_rejects_non_css_content_type
    response = build_response(Net::HTTPOK, "200", "console.log('hi')", "application/javascript")
    downloader = build_downloader([response])

    result = downloader.get("https://cdn.jsdelivr.net/npm/trix")

    refute result[:ok]
    assert_includes result[:error], "Not a CSS file"
  end

  def test_returns_error_for_404
    response = build_response(Net::HTTPNotFound, "404", "Not found", "text/html")
    downloader = build_downloader([response])

    result = downloader.get("https://cdn.jsdelivr.net/npm/nonexistent")

    refute result[:ok]
    assert_equal 404, result[:status]
  end

  def test_follows_redirects
    redirect = Net::HTTPFound.new("1.1", "302", "Found")
    redirect["location"] = "https://cdn.jsdelivr.net/npm/trix@2.0.0/dist/trix.css"

    success = build_response(Net::HTTPOK, "200", "/* redirected css */", "text/css")

    downloader = build_downloader([redirect, success])

    result = downloader.get("https://cdn.jsdelivr.net/npm/trix")

    assert result[:ok]
    assert_equal "/* redirected css */", result[:body]
  end

  def test_follows_relative_redirects
    redirect = Net::HTTPFound.new("1.1", "302", "Found")
    redirect["location"] = "/npm/trix@2.0.0/dist/trix.css"

    success = build_response(Net::HTTPOK, "200", "/* redirected css */", "text/css")

    downloader = build_downloader([redirect, success])

    result = downloader.get("https://cdn.jsdelivr.net/npm/trix")

    assert result[:ok]
    assert_equal "/* redirected css */", result[:body]
  end

  def test_stops_after_max_redirects
    redirect = Net::HTTPFound.new("1.1", "302", "Found")
    redirect["location"] = "https://cdn.jsdelivr.net/npm/loop"

    downloader = build_downloader([redirect] * 10)

    result = downloader.get("https://cdn.jsdelivr.net/npm/loop")

    refute result[:ok]
    assert_includes result[:error], "Too many redirects"
  end

  def test_returns_error_on_invalid_uri
    downloader = Csspin::HTTP::Downloader.new
    result = downloader.get("not a url %%")

    refute result[:ok]
  end

  private

  def build_response(klass, code, body, content_type)
    response = klass.new("1.1", code, "")
    response["content-type"] = content_type
    response.instance_variable_set(:@read, true)
    response.instance_variable_set(:@body, body)
    response
  end

  def build_downloader(responses)
    downloader = TestableDownloader.new
    downloader.http_override = FakeHTTP.new(responses)
    downloader
  end
end
