# frozen_string_literal: true

require "json"

module Csspin
  class JsdelivrMetadataClient
    def initialize(downloader:)
      @downloader = downloader
    end

    def fetch(full_name)
      response = @downloader.get(
        "https://data.jsdelivr.com/v1/packages/npm/#{full_name}",
        allowed_content_types: ["application/json", "text/json"]
      )
      return {} unless response[:ok]

      metadata = JSON.parse(response[:body])
      metadata.is_a?(Hash) ? metadata : {}
    rescue JSON::ParserError, TypeError
      {}
    end
  end
end
