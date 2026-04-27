# frozen_string_literal: true

require "uri"

module Csspin
  class CssImportsInliner
    IMPORT_RE = /\A\s*@import\s+(?:url\(\s*)?["'](?<path>[^"']+)["']\s*\)?\s*(?<media>[^;]*);\s*\z/

    def initialize(downloader:)
      @downloader = downloader
    end

    def inline(css, base_url:, import_stack: [])
      return css unless css.include?("@import")

      out = +""

      css.each_line do |line|
        match = IMPORT_RE.match(line)

        out << if match && relative_css_path?(match[:path]) && match[:media].to_s.strip.empty?
          fetch_css(base_url, match[:path], import_stack)
        else
          line
        end
      end

      out
    end

    private

    def fetch_css(base_url, relative_path, import_stack)
      url = URI.join(base_url, relative_path).to_s

      if import_stack.include?(url)
        raise "Circular CSS import detected: #{(import_stack + [url]).join(" -> ")}"
      end

      response = @downloader.get(url)

      raise "Failed to download imported CSS: #{url}" unless response[:ok]

      import_stack << url
      inlined = inline(response[:body].to_s, base_url: url, import_stack: import_stack)
      inlined.end_with?("\n") ? inlined : "#{inlined}\n"
    ensure
      import_stack.pop if import_stack.last == url
    end

    def relative_css_path?(path)
      return false if path.start_with?("/", "//")
      return false if path.match?(/\A[a-z][a-z0-9+\-.]*:/i)

      true
    end
  end
end
