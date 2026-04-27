# frozen_string_literal: true

module Csspin
  module Commands
    class Pin
      def initialize(resolver:, downloader:, writer:, printer:, fallback_candidates:, error_io: $stderr)
        @resolver = resolver
        @downloader = downloader
        @writer = writer
        @printer = printer
        @error_io = error_io
        @fallback_candidates = fallback_candidates
      end

      def run(input:, root:, io:)
        spec = Csspin::PackageSpec.parse(input)

        urls = @resolver.url_candidates_for(spec)
        tried_urls = []
        result = download_first_success(urls, tried_urls)

        unless result
          fallback_urls = @fallback_candidates.for(spec).reject { |url| tried_urls.include?(url) }
          result = download_first_success(fallback_urls, tried_urls)
        end

        unless result
          @error_io.puts "Unable to download CSS from jsDelivr for #{spec.full_name}"
          @error_io.puts "Tried: #{tried_urls.join(", ")}"
          return 1
        end

        css = Csspin::CssImportsInliner
          .new(downloader: @downloader)
          .inline(result[:body], base_url: result[:url], import_stack: [result[:url]])
        saved_path = @writer.write(package_name: spec.package_name, content: css)

        snippet_package = File.basename(saved_path, ".css")

        @printer.print_success(
          package_name: snippet_package,
          saved_path: saved_path,
          source_url: result[:url]
        )

        0
      rescue ArgumentError => e
        @error_io.puts e.message
        1
      rescue => e
        @error_io.puts "Pin failed: #{e.message}"
        1
      end

      private

      def download_first_success(urls, tried_urls)
        urls.each do |url|
          tried_urls << url
          response = @downloader.get(url)
          return response.merge(url: url) if response[:ok]
        end
        nil
      end
    end
  end
end
