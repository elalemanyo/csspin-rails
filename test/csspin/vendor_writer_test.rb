# frozen_string_literal: true

require_relative "../test_helper"

class CsspinVendorWriterTest < Minitest::Test
  def test_writes_css_to_vendor_stylesheets
    Dir.mktmpdir do |dir|
      writer = Csspin::VendorWriter.new(root: dir)

      path = writer.write(package_name: "trix", content: "/* css */")

      expected = File.join(dir, "vendor/assets/stylesheets/trix.css")
      assert_equal expected, path
      assert_equal "/* css */", File.read(expected)
    end
  end

  def test_creates_directory_if_missing
    Dir.mktmpdir do |dir|
      writer = Csspin::VendorWriter.new(root: dir)

      writer.write(package_name: "trix", content: "/* css */")

      assert Dir.exist?(File.join(dir, "vendor/assets/stylesheets"))
    end
  end

  def test_sanitizes_scoped_package_name
    Dir.mktmpdir do |dir|
      writer = Csspin::VendorWriter.new(root: dir)

      path = writer.write(package_name: "@scope/pkg", content: "/* css */")

      assert path.end_with?("scope-pkg.css")
    end
  end

  def test_prevents_path_traversal
    Dir.mktmpdir do |dir|
      writer = Csspin::VendorWriter.new(root: dir)

      path = writer.write(package_name: "../etc/passwd", content: "/* css */")

      refute path.include?("..")
      assert path.end_with?("etc-passwd.css")
    end
  end
end
