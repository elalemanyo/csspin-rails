# frozen_string_literal: true

require_relative "../test_helper"

class FakeJsonDownloader
  def initialize(response)
    @response = response
  end

  attr_reader :requests

  def get(url, **options)
    @requests ||= []
    @requests << {url:, options:}
    @response
  end
end

class CsspinJsdelivrMetadataClientTest < Minitest::Test
  def test_fetches_and_parses_metadata
    downloader = FakeJsonDownloader.new(
      ok: true,
      body: '{"style":"dist/css/bootstrap.min.css","default":"dist/js/bootstrap.bundle.min.js"}'
    )

    client = Csspin::JsdelivrMetadataClient.new(downloader: downloader)

    metadata = client.fetch("bootstrap@5.3.3")

    assert_equal "dist/css/bootstrap.min.css", metadata["style"]
    assert_equal "dist/js/bootstrap.bundle.min.js", metadata["default"]
  end

  def test_requests_json_content_types_from_downloader
    downloader = FakeJsonDownloader.new(ok: true, body: "{}")

    client = Csspin::JsdelivrMetadataClient.new(downloader: downloader)
    client.fetch("bootstrap@5.3.3")

    assert_equal [
      {
        url: "https://data.jsdelivr.com/v1/packages/npm/bootstrap@5.3.3",
        options: {allowed_content_types: ["application/json", "text/json"]}
      }
    ], downloader.requests
  end
end
