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

class FakeMultiJsonDownloader
  def initialize(responses)
    @responses = responses
  end

  attr_reader :requests

  def get(url, **options)
    @requests ||= []
    @requests << {url:, options:}
    @responses[url] || {ok: false}
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

  def test_refetches_with_latest_version_when_unversioned_response_lacks_files
    unversioned_body = '{"type":"npm","name":"sourdough-toast","tags":{"latest":"0.1.0"},"versions":[]}'
    versioned_body = '{"type":"npm","name":"sourdough-toast","version":"0.1.0","default":"/src/sourdough-toast.min.js","files":[{"type":"directory","name":"src","files":[{"type":"file","name":"sourdough-toast.css"}]}]}'

    downloader = FakeMultiJsonDownloader.new(
      "https://data.jsdelivr.com/v1/packages/npm/sourdough-toast" => {ok: true, body: unversioned_body},
      "https://data.jsdelivr.com/v1/packages/npm/sourdough-toast@0.1.0" => {ok: true, body: versioned_body}
    )

    client = Csspin::JsdelivrMetadataClient.new(downloader: downloader)
    metadata = client.fetch("sourdough-toast")

    assert_equal "/src/sourdough-toast.min.js", metadata["default"]
    assert_equal 2, downloader.requests.size
  end

  def test_does_not_refetch_when_versioned_response_has_files
    body = '{"files":[{"type":"file","name":"style.css"}],"default":"style.css"}'

    downloader = FakeJsonDownloader.new(ok: true, body: body)

    client = Csspin::JsdelivrMetadataClient.new(downloader: downloader)
    metadata = client.fetch("bootstrap@5.3.3")

    assert_equal "style.css", metadata["default"]
    assert_equal 1, downloader.requests.size
  end

  def test_returns_empty_hash_when_download_fails
    downloader = FakeJsonDownloader.new(ok: false)

    client = Csspin::JsdelivrMetadataClient.new(downloader: downloader)
    metadata = client.fetch("nonexistent")

    assert_equal({}, metadata)
  end
end
