# frozen_string_literal: true

require "minitest/autorun"
require_relative "test_helper"

class SmokeTest < Minitest::Test
  def test_module_loads
    assert defined?(Csspin)
    assert Csspin::VERSION
  end
end
