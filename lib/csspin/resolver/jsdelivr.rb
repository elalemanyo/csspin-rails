# frozen_string_literal: true

module Csspin
  module Resolver
    class Jsdelivr
      def url_candidates_for(package_spec)
        full = package_spec.full_name
        package = package_spec.package_name

        [
          "https://cdn.jsdelivr.net/npm/#{full}/dist/#{package}.css",
          "https://cdn.jsdelivr.net/npm/#{full}"
        ]
      end
    end
  end
end
