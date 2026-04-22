# frozen_string_literal: true

module Csspin
  class PackageSpec
    attr_reader :full_name, :package_name

    def self.parse(raw)
      normalized = raw.to_s.strip
      raise ArgumentError, "package is required" if normalized.empty?

      package_part, = split_package_and_version(normalized)

      package_name = package_part.split("/").last
      new(full_name: normalized, package_name: package_name)
    end

    def self.split_package_and_version(normalized)
      return validate_unscoped_package!(normalized) unless normalized.include?("@")

      if normalized.start_with?("@")
        scope, remainder = normalized.split("/", 2)
        raise ArgumentError, "invalid package format: #{normalized}" if scope.nil? || scope.length == 1 || scope.count("@") != 1 || remainder.nil? || remainder.empty?

        package, version = remainder.split("@", 2)
        raise ArgumentError, "invalid package format: #{normalized}" if package.nil? || package.empty? || package.include?("/") || version&.empty? || version&.include?("/") || version&.include?("@")

        ["#{scope}/#{package}", version]
      else
        package, version = normalized.split("@", 2)
        raise ArgumentError, "invalid package format: #{normalized}" if package.nil? || package.empty? || package.include?("/") || version&.empty? || version&.include?("/") || version&.include?("@")

        [package, version]
      end
    end

    def self.validate_unscoped_package!(normalized)
      raise ArgumentError, "invalid package format: #{normalized}" if normalized.empty? || normalized.include?("/")

      [normalized, nil]
    end

    def initialize(full_name:, package_name:)
      @full_name = full_name
      @package_name = package_name
    end
  end
end
