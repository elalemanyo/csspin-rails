# frozen_string_literal: true

module Csspin
  class CssFallbackCandidates
    def initialize(metadata_client:)
      @metadata_client = metadata_client
    end

    def for(package_spec)
      metadata = @metadata_client.fetch(package_spec.full_name)

      [
        metadata_path_for(metadata, "style"),
        metadata_path_for(metadata, "default"),
        conventional_path_for(package_spec, "dist/css/"),
        conventional_path_for(package_spec)
      ].compact.map { |path| normalize_path(path, package_spec.full_name) }
        .uniq
        .map { |path| candidate_url_for(path, package_spec.full_name) }
    end

    private

    def metadata_path_for(metadata, key)
      path = metadata[key]
      path if path&.end_with?(".css")
    end

    def conventional_path_for(package_spec, prefix = "")
      "#{prefix}#{package_spec.package_name}.min.css"
    end

    def normalize_path(path, full_name)
      path.sub("https://cdn.jsdelivr.net/npm/#{full_name}/", "")
    end

    def candidate_url_for(path, full_name)
      return path if path.start_with?("https://cdn.jsdelivr.net/npm/")

      "https://cdn.jsdelivr.net/npm/#{full_name}/#{path}"
    end
  end
end
