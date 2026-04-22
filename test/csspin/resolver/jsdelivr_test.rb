# frozen_string_literal: true

require_relative "../../test_helper"

class CsspinResolverJsdelivrTest < Minitest::Test
  def test_returns_dist_and_root_candidates_in_order
    spec = Csspin::PackageSpec.parse("trix@2.0.0")

    urls = Csspin::Resolver::Jsdelivr.new.url_candidates_for(spec)

    assert_equal [
      "https://cdn.jsdelivr.net/npm/trix@2.0.0/dist/trix.css",
      "https://cdn.jsdelivr.net/npm/trix@2.0.0"
    ], urls
  end

  def test_unversioned_package
    spec = Csspin::PackageSpec.parse("trix")

    urls = Csspin::Resolver::Jsdelivr.new.url_candidates_for(spec)

    assert_equal [
      "https://cdn.jsdelivr.net/npm/trix/dist/trix.css",
      "https://cdn.jsdelivr.net/npm/trix"
    ], urls
  end

  def test_scoped_versioned_package
    spec = Csspin::PackageSpec.parse("@scope/pkg@1.2.3")

    urls = Csspin::Resolver::Jsdelivr.new.url_candidates_for(spec)

    assert_equal [
      "https://cdn.jsdelivr.net/npm/@scope/pkg@1.2.3/dist/pkg.css",
      "https://cdn.jsdelivr.net/npm/@scope/pkg@1.2.3"
    ], urls
  end

  def test_scoped_unversioned_package
    spec = Csspin::PackageSpec.parse("@scope/pkg")

    urls = Csspin::Resolver::Jsdelivr.new.url_candidates_for(spec)

    assert_equal [
      "https://cdn.jsdelivr.net/npm/@scope/pkg/dist/pkg.css",
      "https://cdn.jsdelivr.net/npm/@scope/pkg"
    ], urls
  end
end
