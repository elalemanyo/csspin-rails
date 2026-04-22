# frozen_string_literal: true

module Csspin
  class InstructionsPrinter
    def initialize(io: $stdout)
      @io = io
    end

    def print_success(package_name:, saved_path:, source_url:)
      @io.puts "Saved CSS to: #{saved_path}"
      @io.puts "Source URL: #{source_url}"
      @io.puts
      @io.puts "Sprockets snippet: *= require #{package_name}"
      @io.puts "Sass snippet: @import \"#{package_name}\";"
    end
  end
end
