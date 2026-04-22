# csspin-rails

Pin CSS packages from npm into a Rails app's `vendor/assets/stylesheets` — without Node.js.

Works like [importmap-rails](https://github.com/rails/importmap-rails), but for CSS. Packages are fetched from [jsDelivr](https://www.jsdelivr.com/).

## Installation

Add to your Gemfile:

```ruby
gem "csspin-rails"
```

Then run:

```bash
bundle install
```

## Usage

```bash
# Pin a package (latest version)
bundle exec csspin pin trix

# Pin a specific version
bundle exec csspin pin trix@2.0.0

# Pin a scoped package
bundle exec csspin pin @scope/package@1.2.3
```

CSS is saved to `vendor/assets/stylesheets/<package>.css`.

If you want `bin/csspin`, run `bundle binstubs csspin-rails` first.

After pinning, the CLI prints integration snippets:

```
Sprockets snippet: *= require trix
Sass snippet: @import "trix";
```

## CLI

```
Usage: csspin pin <package|package@version>

Commands:
  pin <package|package@version>  Download a CSS package into vendor/assets/stylesheets

Options:
  -v, --version  Show version
  -h, --help     Show this help
```

## How it works

1. Parses the package name and optional version
2. Resolves candidate URLs on jsDelivr (`/dist/<pkg>.css`, then the bare package URL)
3. Downloads the first successful CSS response (follows redirects, validates content-type)
4. Writes the file to `vendor/assets/stylesheets/`

## Development

```bash
bundle install
bundle exec standardrb
bundle exec rake test
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
