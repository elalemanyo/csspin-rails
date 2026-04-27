# csspin-rails

![Gem Version](https://img.shields.io/gem/v/csspin-rails)
![CI](https://github.com/elalemanyo/csspin-rails/actions/workflows/ci.yml/badge.svg)
![License](https://img.shields.io/badge/License-MIT-green)

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
bundle exec csspin pin sourdough-toast

# Pin a specific version
  bundle exec csspin pin sourdough-toast@2.0.7

# Pin a scoped package
bundle exec csspin pin @37signals/lexxy
```

CSS is saved to `vendor/assets/stylesheets/<package>.css`.

If you want `bin/csspin`, run `bundle binstubs csspin-rails` first.

After pinning, the CLI prints integration snippets:

```
Sprockets snippet: *= require sourdough-toast
Sass snippet: @import "sourdough-toast";
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

### Releasing

This repo publishes via GitHub Actions when you push a tag matching `v*` (see `.github/workflows/release.yml`).

1. Update `lib/csspin/version.rb`
2. Run `bundle exec rake test` (and any linting you want)
3. Commit
4. Tag: `git tag vX.Y.Z`
5. Push commit: `git push origin HEAD`
6. Push tag: `git push origin vX.Y.Z`

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
