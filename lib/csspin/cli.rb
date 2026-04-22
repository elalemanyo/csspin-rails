# frozen_string_literal: true

module Csspin
  class CLI
    USAGE = "Usage: csspin pin <package|package@version>"

    def self.run(argv:, root: Dir.pwd, io: $stdout, error_io: $stderr, pin_command: nil)
      command = argv[0]

      if command == "--version" || command == "-v"
        io.puts "csspin-rails #{Csspin::VERSION}"
        return 0
      end

      if command == "--help" || command == "-h" || command.nil?
        io.puts USAGE
        io.puts
        io.puts "Commands:"
        io.puts "  pin <package|package@version>  Download a CSS package into vendor/assets/stylesheets"
        io.puts
        io.puts "Options:"
        io.puts "  -v, --version  Show version"
        io.puts "  -h, --help     Show this help"
        return 0
      end

      unless command == "pin"
        error_io.puts "Unknown command: #{command}"
        error_io.puts USAGE
        return 1
      end

      input = argv[1]
      if input.to_s.strip.empty?
        error_io.puts USAGE
        return 1
      end

      downloader = Csspin::HTTP::Downloader.new

      cmd = pin_command || Csspin::Commands::Pin.new(
        resolver: Csspin::Resolver::Jsdelivr.new,
        downloader: downloader,
        fallback_candidates: Csspin::CssFallbackCandidates.new(
          metadata_client: Csspin::JsdelivrMetadataClient.new(downloader: downloader)
        ),
        writer: Csspin::VendorWriter.new(root: root),
        printer: Csspin::InstructionsPrinter.new(io: io),
        error_io: error_io
      )

      cmd.run(input: input, root: root, io: io)
    rescue ArgumentError => e
      error_io.puts e.message
      error_io.puts USAGE
      1
    end
  end
end
