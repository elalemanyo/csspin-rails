# frozen_string_literal: true

require_relative "../test_helper"

class FakeMetadataClient
  def initialize(metadata)
    @metadata = metadata
  end

  def fetch(_full_name)
    @metadata
  end
end

class CsspinCssFallbackCandidatesTest < Minitest::Test
  def test_uses_style_field_first
    package = Csspin::PackageSpec.parse("bootstrap@5.3.3")
    builder = Csspin::CssFallbackCandidates.new(
      metadata_client: FakeMetadataClient.new({"style" => "dist/css/bootstrap.min.css"})
    )

    assert_equal [
      "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css",
      "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/bootstrap.min.css"
    ], builder.for(package)
  end

  def test_uses_default_when_it_points_to_css
    package = Csspin::PackageSpec.parse("normalize.css@8.0.1")
    builder = Csspin::CssFallbackCandidates.new(
      metadata_client: FakeMetadataClient.new({"default" => "normalize.css"})
    )

    assert_equal [
      "https://cdn.jsdelivr.net/npm/normalize.css@8.0.1/normalize.css",
      "https://cdn.jsdelivr.net/npm/normalize.css@8.0.1/dist/css/normalize.css.min.css",
      "https://cdn.jsdelivr.net/npm/normalize.css@8.0.1/normalize.css.min.css"
    ], builder.for(package)
  end

  def test_orders_style_then_default_then_conventional_candidates
    package = Csspin::PackageSpec.parse("bootstrap@5.3.3")
    builder = Csspin::CssFallbackCandidates.new(
      metadata_client: FakeMetadataClient.new(
        {
          "style" => "dist/css/bootstrap.min.css",
          "default" => "themes/bootstrap.css"
        }
      )
    )

    assert_equal [
      "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css",
      "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/themes/bootstrap.css",
      "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/bootstrap.min.css"
    ], builder.for(package)
  end

  def test_returns_only_conventional_candidates_when_metadata_has_no_css_hint
    package = Csspin::PackageSpec.parse("bootstrap")
    builder = Csspin::CssFallbackCandidates.new(
      metadata_client: FakeMetadataClient.new({"default" => "dist/js/bootstrap.bundle.js"})
    )

    assert_equal [
      "https://cdn.jsdelivr.net/npm/bootstrap/dist/css/bootstrap.min.css",
      "https://cdn.jsdelivr.net/npm/bootstrap/bootstrap.min.css"
    ], builder.for(package)
  end

  def test_normalizes_absolute_jsdelivr_metadata_urls_and_deduplicates_after_normalization
    package = Csspin::PackageSpec.parse("bootstrap@5.3.3")
    builder = Csspin::CssFallbackCandidates.new(
      metadata_client: FakeMetadataClient.new(
        {"style" => "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"}
      )
    )

    assert_equal [
      "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css",
      "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/bootstrap.min.css"
    ], builder.for(package)
  end

  def test_does_not_normalize_absolute_jsdelivr_urls_for_a_different_full_name
    package = Csspin::PackageSpec.parse("bootstrap")
    builder = Csspin::CssFallbackCandidates.new(
      metadata_client: FakeMetadataClient.new(
        {"style" => "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css"}
      )
    )

    assert_equal [
      "https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css",
      "https://cdn.jsdelivr.net/npm/bootstrap/dist/css/bootstrap.min.css",
      "https://cdn.jsdelivr.net/npm/bootstrap/bootstrap.min.css"
    ], builder.for(package)
  end
end
