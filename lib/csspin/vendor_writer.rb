# frozen_string_literal: true

require "fileutils"

module Csspin
  class VendorWriter
    def initialize(root: Dir.pwd)
      @root = root
    end

    def write(package_name:, content:)
      package_name = package_name.tr("/", "-").gsub(/[^a-zA-Z0-9\-_]/, "")

      dir = File.join(@root, "vendor/assets/stylesheets")
      FileUtils.mkdir_p(dir)

      path = File.join(dir, "#{package_name}.css")
      File.write(path, content)
      path
    rescue Errno::ENOENT, Errno::EACCES => e
      raise "Failed to write vendor file: #{e.message}"
    end
  end
end
