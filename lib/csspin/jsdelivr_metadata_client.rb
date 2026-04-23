# frozen_string_literal: true

require "json"

module Csspin
  class JsdelivrMetadataClient
    def initialize(downloader:)
      @downloader = downloader
    end

    def fetch(full_name)
      metadata = fetch_json(full_name)
      return {} unless metadata

      if !metadata.key?("files") && (latest = resolve_latest_version(metadata))
        versioned = fetch_json("#{full_name}@#{latest}")
        return versioned if versioned
      end

      metadata
    end

    private

    def fetch_json(full_name)
      response = @downloader.get(
        "https://data.jsdelivr.com/v1/packages/npm/#{full_name}",
        allowed_content_types: ["application/json", "text/json"]
      )
      return nil unless response[:ok]

      metadata = JSON.parse(response[:body])
      metadata.is_a?(Hash) ? metadata : nil
    rescue JSON::ParserError, TypeError
      nil
    end

    def resolve_latest_version(metadata)
      metadata.dig("tags", "latest")
    end
  end
end
