# frozen_string_literal: true

require_relative "../test_helper"

class CsspinPackageSpecTest < Minitest::Test
  def test_parses_unversioned_package
    spec = Csspin::PackageSpec.parse("trix")

    assert_equal "trix", spec.full_name
    assert_equal "trix", spec.package_name
  end

  def test_parses_versioned_package
    spec = Csspin::PackageSpec.parse("trix@2.0.0")

    assert_equal "trix@2.0.0", spec.full_name
    assert_equal "trix", spec.package_name
  end

  def test_parses_scoped_package
    spec = Csspin::PackageSpec.parse("@hotwired/turbo")

    assert_equal "@hotwired/turbo", spec.full_name
    assert_equal "turbo", spec.package_name
  end

  def test_parses_scoped_versioned_package
    spec = Csspin::PackageSpec.parse("@hotwired/turbo@2.0.0")

    assert_equal "@hotwired/turbo@2.0.0", spec.full_name
    assert_equal "turbo", spec.package_name
  end

  def test_rejects_blank_spec
    assert_raises(ArgumentError) { Csspin::PackageSpec.parse("") }
  end

  def test_rejects_empty_scope
    assert_raises(ArgumentError) { Csspin::PackageSpec.parse("@/foo") }
  end

  def test_rejects_missing_package_in_scope
    assert_raises(ArgumentError) { Csspin::PackageSpec.parse("@scope/") }
  end

  def test_rejects_extra_path_segments
    assert_raises(ArgumentError) { Csspin::PackageSpec.parse("@scope/foo/bar") }
  end

  def test_rejects_empty_version_suffix
    assert_raises(ArgumentError) { Csspin::PackageSpec.parse("foo@") }
  end

  def test_rejects_unscoped_path_segments
    assert_raises(ArgumentError) { Csspin::PackageSpec.parse("foo/bar") }
  end

  def test_rejects_scoped_path_segments_after_version
    assert_raises(ArgumentError) { Csspin::PackageSpec.parse("@scope/foo@1/bar") }
  end

  def test_rejects_malformed_scope_tokens
    assert_raises(ArgumentError) { Csspin::PackageSpec.parse("@@scope/pkg") }
    assert_raises(ArgumentError) { Csspin::PackageSpec.parse("@scope@x/pkg") }
  end
end
