# frozen_string_literal: true

require_relative "../test_helper"

class CsspinInstructionsPrinterTest < Minitest::Test
  def test_prints_success_and_both_integration_snippets
    out = StringIO.new

    Csspin::InstructionsPrinter.new(io: out).print_success(
      package_name: "trix",
      saved_path: "vendor/assets/stylesheets/trix.css",
      source_url: "https://cdn.jsdelivr.net/npm/trix"
    )

    text = out.string
    assert_includes text, "Saved CSS to: vendor/assets/stylesheets/trix.css"
    assert_includes text, "Source URL: https://cdn.jsdelivr.net/npm/trix"
    assert_includes text, "*= require trix"
    assert_includes text, "@import \"trix\";"
  end
end
