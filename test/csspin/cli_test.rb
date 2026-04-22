# frozen_string_literal: true

require_relative "../test_helper"

class CsspinCliTest < Minitest::Test
  private

  def with_replaced_pin_command_class(replacement)
    original = Csspin::Commands.send(:remove_const, :Pin)
    Csspin::Commands.const_set(:Pin, replacement)
    yield
  ensure
    Csspin::Commands.send(:remove_const, :Pin)
    Csspin::Commands.const_set(:Pin, original)
  end

  public

  def test_shows_help_for_no_arguments
    out = StringIO.new
    err = StringIO.new

    code = Csspin::CLI.run(argv: [], io: out, error_io: err)

    assert_equal 0, code
    assert_includes out.string, "Usage:"
    assert_includes out.string, "Commands:"
  end

  def test_shows_help_with_help_flag
    out = StringIO.new
    err = StringIO.new

    code = Csspin::CLI.run(argv: ["--help"], io: out, error_io: err)

    assert_equal 0, code
    assert_includes out.string, "Usage:"
  end

  def test_shows_help_with_short_flag
    out = StringIO.new
    err = StringIO.new

    code = Csspin::CLI.run(argv: ["-h"], io: out, error_io: err)

    assert_equal 0, code
    assert_includes out.string, "Usage:"
  end

  def test_shows_version
    out = StringIO.new
    err = StringIO.new

    code = Csspin::CLI.run(argv: ["--version"], io: out, error_io: err)

    assert_equal 0, code
    assert_includes out.string, Csspin::VERSION
  end

  def test_shows_version_with_short_flag
    out = StringIO.new
    err = StringIO.new

    code = Csspin::CLI.run(argv: ["-v"], io: out, error_io: err)

    assert_equal 0, code
    assert_includes out.string, Csspin::VERSION
  end

  def test_returns_error_for_invalid_command
    out = StringIO.new
    err = StringIO.new

    code = Csspin::CLI.run(argv: ["invalid"], io: out, error_io: err)

    assert_equal 1, code
    assert_includes err.string, "Unknown command: invalid"
    assert_includes err.string, "Usage:"
  end

  def test_returns_error_for_missing_pin_package
    out = StringIO.new
    err = StringIO.new

    code = Csspin::CLI.run(argv: ["pin"], io: out, error_io: err)

    assert_equal 1, code
    assert_includes err.string, "Usage:"
  end

  def test_dispatches_to_pin_command
    out = StringIO.new
    err = StringIO.new

    fake_pin = Class.new do
      def run(input:, root:, io:)
        0
      end
    end

    code = Csspin::CLI.run(argv: ["pin", "trix"], io: out, error_io: err, pin_command: fake_pin.new)

    assert_equal 0, code
  end

  def test_passes_package_to_pin_command
    out = StringIO.new
    err = StringIO.new

    fake_pin = Class.new do
      attr_reader :received

      def run(input:, **kwargs)
        @received = input
        0
      end
    end.new

    Csspin::CLI.run(argv: ["pin", "trix@2.0.0"], io: out, error_io: err, pin_command: fake_pin)

    assert_equal "trix@2.0.0", fake_pin.received
  end

  def test_builds_pin_command_with_fallback_candidates_dependency
    pin_command = Object.new
    out = StringIO.new
    err = StringIO.new
    fake_pin_class = Class.new do
      class << self
        attr_accessor :last_kwargs, :pin_command

        def new(**kwargs)
          self.last_kwargs = kwargs
          pin_command
        end
      end
    end
    fake_pin_class.pin_command = pin_command

    with_replaced_pin_command_class(fake_pin_class) do
      pin_command.define_singleton_method(:run) { |**| 0 }

      code = Csspin::CLI.run(argv: ["pin", "trix"], io: out, error_io: err)

      assert_equal 0, code
      assert_instance_of Csspin::CssFallbackCandidates, fake_pin_class.last_kwargs[:fallback_candidates]
    end
  end
end
