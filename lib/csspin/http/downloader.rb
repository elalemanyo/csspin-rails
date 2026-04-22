# frozen_string_literal: true

require "net/http"
require "uri"

module Csspin
  module HTTP
    class Downloader
      MAX_REDIRECTS = 5
      DEFAULT_ALLOWED_CONTENT_TYPES = ["text/css", "text/plain"].freeze

      def get(url, allowed_content_types: DEFAULT_ALLOWED_CONTENT_TYPES)
        uri = URI.parse(url)
        redirects = 0

        loop do
          http = build_http(uri)
          response = http.start { |h| h.get(uri.request_uri) }

          if response.is_a?(Net::HTTPRedirection)
            redirects += 1
            return {ok: false, error: "Too many redirects", status: response.code.to_i} if redirects > MAX_REDIRECTS

            location = response["location"]
            uri = URI.join(uri, location)
            next
          end

          if response.is_a?(Net::HTTPSuccess)
            content_type = response["content-type"].to_s
            unless allowed_content_types.any? { |allowed_content_type| content_type.include?(allowed_content_type) }
              return {ok: false, error: "Not a CSS file (content-type: #{content_type})", status: response.code.to_i}
            end

            return {ok: true, body: response.body}
          end

          return {ok: false, error: "HTTP #{response.code}", status: response.code.to_i}
        end
      rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, SocketError, URI::InvalidURIError => e
        {ok: false, error: e.message, status: nil}
      end

      private

      def build_http(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 5
        http.read_timeout = 10
        http.write_timeout = 5
        http
      end
    end
  end
end
