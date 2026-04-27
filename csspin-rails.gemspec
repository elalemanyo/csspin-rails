require_relative "lib/csspin/version"

Gem::Specification.new do |spec|
  spec.name = "csspin-rails"
  spec.version = Csspin::VERSION
  spec.authors = ["elalemanyo"]
  spec.summary = "Pin CSS dependencies into Rails vendor assets"
  spec.description = "A CLI tool to pin CSS packages from npm (via jsDelivr) into a Rails app's vendor/assets/stylesheets without Node.js."
  spec.homepage = "https://github.com/elalemanyo/csspin-rails"
  spec.license = "MIT"
  spec.files = Dir["lib/**/*", "exe/*", "README*", "CHANGELOG*"]
  spec.bindir = "exe"
  spec.executables = ["csspin"]
  spec.require_paths = ["lib"]
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "standard"
end
