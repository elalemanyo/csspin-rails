# frozen_string_literal: true

require_relative "../../test_helper"

class FakeResolver
  def initialize(urls)
    @urls = urls
  end

  def url_candidates_for(_spec)
    @urls
  end
end

class FakeDownloader
  attr_reader :requested_urls

  def initialize(results)
    @results = results
    @requested_urls = []
  end

  def get(url)
    @requested_urls << url
    @results.shift
  end
end

class FakeWriter
  attr_reader :writes

  def initialize(path)
    @path = path
    @writes = []
  end

  def write(package_name:, content:)
    @writes << [package_name, content]
    @path
  end
end

class FakePrinter
  attr_reader :called_with

  def print_success(**kwargs)
    @called_with = kwargs
  end
end

class FakeFallbackCandidates
  attr_reader :requested_for

  def initialize(urls)
    @urls = urls
    @requested_for = []
  end

  def for(package_spec)
    @requested_for << package_spec.full_name
    @urls
  end
end

class NullFallbackCandidates < FakeFallbackCandidates
  def initialize
    super([])
  end
end

class CsspinCommandsPinTest < Minitest::Test
  def test_run_does_not_accept_duplicate_error_io_keyword
    resolver = FakeResolver.new([])
    downloader = FakeDownloader.new([])
    writer = FakeWriter.new("unused")
    printer = FakePrinter.new
    error_io = StringIO.new

    error = assert_raises(ArgumentError) do
      Csspin::Commands::Pin.new(
        resolver: resolver,
        downloader: downloader,
        writer: writer,
        printer: printer,
        error_io: error_io,
        fallback_candidates: NullFallbackCandidates.new
      ).run(input: "bootstrap", root: ".", io: StringIO.new, error_io: error_io)
    end

    assert_includes error.message, "unknown keyword: :error_io"
  end

  def test_requires_fallback_candidates_dependency
    error = assert_raises(ArgumentError) do
      Csspin::Commands::Pin.new(
        resolver: FakeResolver.new([]),
        downloader: FakeDownloader.new([]),
        writer: FakeWriter.new("unused"),
        printer: FakePrinter.new,
        error_io: StringIO.new
      )
    end

    assert_includes error.message, "fallback_candidates"
  end

  def test_pins_first_successful_candidate
    resolver = FakeResolver.new(["u1", "u2"])
    downloader = FakeDownloader.new([
      {ok: false, error: "404", status: 404},
      {ok: true, body: "/* css */"}
    ])
    writer = FakeWriter.new("vendor/assets/stylesheets/trix.css")
    printer = FakePrinter.new
    error_io = StringIO.new
    fallback_candidates = NullFallbackCandidates.new

    code = Csspin::Commands::Pin.new(
      resolver: resolver,
      downloader: downloader,
      writer: writer,
      printer: printer,
      error_io: error_io,
      fallback_candidates: fallback_candidates
    ).run(input: "trix", root: ".", io: StringIO.new)

    assert_equal 0, code
    assert_equal [["trix", "/* css */"]], writer.writes
    assert_equal "u2", printer.called_with[:source_url]
    assert_empty fallback_candidates.requested_for
  end

  def test_returns_error_when_all_candidates_fail
    resolver = FakeResolver.new(["u1", "u2"])
    downloader = FakeDownloader.new([
      {ok: false, error: "404", status: 404},
      {ok: false, error: "404", status: 404}
    ])
    writer = FakeWriter.new("unused")
    error_io = StringIO.new
    fallback_candidates = NullFallbackCandidates.new

    code = Csspin::Commands::Pin.new(
      resolver: resolver,
      downloader: downloader,
      writer: writer,
      printer: FakePrinter.new,
      error_io: error_io,
      fallback_candidates: fallback_candidates
    ).run(input: "trix", root: ".", io: StringIO.new)

    assert_equal 1, code
    assert_includes error_io.string, "Unable to download CSS"
    assert_equal ["trix"], fallback_candidates.requested_for
  end

  def test_tries_fallback_candidates_after_guessed_candidates_fail
    resolver = FakeResolver.new(["u1", "u2"])
    downloader = FakeDownloader.new([
      {ok: false, error: "404", status: 404},
      {ok: false, error: "404", status: 404},
      {ok: true, body: "/* fallback css */"}
    ])
    writer = FakeWriter.new("vendor/assets/stylesheets/bootstrap.css")
    printer = FakePrinter.new
    error_io = StringIO.new
    fallback_candidates = FakeFallbackCandidates.new(["u3"])

    code = Csspin::Commands::Pin.new(
      resolver: resolver,
      downloader: downloader,
      writer: writer,
      printer: printer,
      error_io: error_io,
      fallback_candidates: fallback_candidates
    ).run(input: "bootstrap", root: ".", io: StringIO.new)

    assert_equal 0, code
    assert_equal ["bootstrap"], fallback_candidates.requested_for
    assert_equal "u3", printer.called_with[:source_url]
    assert_equal [["bootstrap", "/* fallback css */"]], writer.writes
  end

  def test_deduplicates_fallback_candidates_against_guessed_urls
    resolver = FakeResolver.new(["u1", "u2"])
    downloader = FakeDownloader.new([
      {ok: false, error: "404", status: 404},
      {ok: false, error: "404", status: 404}
    ])
    writer = FakeWriter.new("unused")
    error_io = StringIO.new
    fallback_candidates = FakeFallbackCandidates.new(["u2", "u1"])

    code = Csspin::Commands::Pin.new(
      resolver: resolver,
      downloader: downloader,
      writer: writer,
      printer: FakePrinter.new,
      error_io: error_io,
      fallback_candidates: fallback_candidates
    ).run(input: "bootstrap", root: ".", io: StringIO.new)

    assert_equal 1, code
    assert_equal ["u1", "u2"], downloader.requested_urls
    assert_includes error_io.string, "Tried: u1, u2"
  end

  def test_uses_vendored_filename_for_snippets
    resolver = FakeResolver.new(["u1"])
    downloader = FakeDownloader.new([{ok: true, body: "/* css */"}])
    writer = FakeWriter.new("vendor/assets/stylesheets/scope-pkg.css")
    printer = FakePrinter.new
    error_io = StringIO.new
    fallback_candidates = NullFallbackCandidates.new

    Csspin::Commands::Pin.new(
      resolver: resolver,
      downloader: downloader,
      writer: writer,
      printer: printer,
      error_io: error_io,
      fallback_candidates: fallback_candidates
    ).run(input: "@scope/pkg", root: ".", io: StringIO.new)

    assert_equal "scope-pkg", printer.called_with[:package_name]
    assert_empty fallback_candidates.requested_for
  end

  def test_does_not_consult_fallback_candidates_when_guessed_url_succeeds
    resolver = FakeResolver.new(["u1", "u2"])
    downloader = FakeDownloader.new([{ok: true, body: "/* css */"}])
    writer = FakeWriter.new("vendor/assets/stylesheets/trix.css")
    printer = FakePrinter.new
    error_io = StringIO.new
    fallback_candidates = FakeFallbackCandidates.new(["u3"])

    code = Csspin::Commands::Pin.new(
      resolver: resolver,
      downloader: downloader,
      writer: writer,
      printer: printer,
      error_io: error_io,
      fallback_candidates: fallback_candidates
    ).run(input: "trix", root: ".", io: StringIO.new)

    assert_equal 0, code
    assert_empty fallback_candidates.requested_for
    assert_equal "u1", printer.called_with[:source_url]
  end

  def test_returns_normal_error_when_fallback_candidates_are_empty
    resolver = FakeResolver.new(["u1", "u2"])
    downloader = FakeDownloader.new([
      {ok: false, error: "404", status: 404},
      {ok: false, error: "404", status: 404}
    ])
    writer = FakeWriter.new("unused")
    printer = FakePrinter.new
    error_io = StringIO.new
    fallback_candidates = FakeFallbackCandidates.new([])

    code = Csspin::Commands::Pin.new(
      resolver: resolver,
      downloader: downloader,
      writer: writer,
      printer: printer,
      error_io: error_io,
      fallback_candidates: fallback_candidates
    ).run(input: "bootstrap", root: ".", io: StringIO.new)

    assert_equal 1, code
    assert_equal ["bootstrap"], fallback_candidates.requested_for
    assert_includes error_io.string, "Unable to download CSS from jsDelivr for bootstrap"
  end

  def test_inlines_relative_css_imports
    base_url = "https://cdn.jsdelivr.net/npm/@37signals/lexxy/dist/stylesheets/lexxy.css"
    resolver = FakeResolver.new([base_url])
    downloader = FakeDownloader.new([
      {ok: true, body: "@import url(\"lexxy-content.css\");\n@import url(\"lexxy-editor.css\");\n"},
      {ok: true, body: "/* content */\n"},
      {ok: true, body: "/* editor */\n"}
    ])
    writer = FakeWriter.new("vendor/assets/stylesheets/lexxy.css")
    printer = FakePrinter.new
    error_io = StringIO.new
    fallback_candidates = NullFallbackCandidates.new

    code = Csspin::Commands::Pin.new(
      resolver: resolver,
      downloader: downloader,
      writer: writer,
      printer: printer,
      error_io: error_io,
      fallback_candidates: fallback_candidates
    ).run(input: "@37signals/lexxy", root: ".", io: StringIO.new)

    assert_equal 0, code
    assert_equal [["lexxy", "/* content */\n/* editor */\n"]], writer.writes
    assert_equal [
      base_url,
      "https://cdn.jsdelivr.net/npm/@37signals/lexxy/dist/stylesheets/lexxy-content.css",
      "https://cdn.jsdelivr.net/npm/@37signals/lexxy/dist/stylesheets/lexxy-editor.css"
    ], downloader.requested_urls
  end

  def test_inlines_nested_relative_css_imports
    base_url = "https://cdn.jsdelivr.net/npm/@37signals/lexxy/dist/stylesheets/lexxy.css"
    resolver = FakeResolver.new([base_url])
    downloader = FakeDownloader.new([
      {ok: true, body: "@import url(\"lexxy-content.css\");\n"},
      {ok: true, body: "@import url(\"lexxy-variables.css\");\n/* content */\n"},
      {ok: true, body: "/* variables */\n"}
    ])
    writer = FakeWriter.new("vendor/assets/stylesheets/lexxy.css")
    printer = FakePrinter.new
    error_io = StringIO.new
    fallback_candidates = NullFallbackCandidates.new

    code = Csspin::Commands::Pin.new(
      resolver: resolver,
      downloader: downloader,
      writer: writer,
      printer: printer,
      error_io: error_io,
      fallback_candidates: fallback_candidates
    ).run(input: "@37signals/lexxy", root: ".", io: StringIO.new)

    assert_equal 0, code
    assert_equal [["lexxy", "/* variables */\n/* content */\n"]], writer.writes
    assert_equal [
      base_url,
      "https://cdn.jsdelivr.net/npm/@37signals/lexxy/dist/stylesheets/lexxy-content.css",
      "https://cdn.jsdelivr.net/npm/@37signals/lexxy/dist/stylesheets/lexxy-variables.css"
    ], downloader.requested_urls
  end
end
