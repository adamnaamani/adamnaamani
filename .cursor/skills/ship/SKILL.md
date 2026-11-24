---
name: ship
description: >-
  Ship this Jekyll site to GitHub Pages on the latest stable Ruby and
  the latest stable Jekyll. Use when deploying, shipping, pushing to
  main, editing .github/workflows/pages.yml, changing .ruby-version or
  the Jekyll gem, or when a ruby/setup-ruby job fails with an
  unavailable Ruby version.
---

# Ship

Deploy is `.github/workflows/pages.yml`. Always update to the latest stable Ruby and the latest stable Jekyll before shipping. `ubuntu-latest` only has the latest patch of each Ruby series, so a stale patch in `ruby-version` makes `ruby/setup-ruby` return HTTP 404 and the build never starts.

## Before a deploy

1. Read `.github/workflows/pages.yml` and `.ruby-version`.
2. In both the `build` and `verify` jobs, set `ruby/setup-ruby` to the latest stable release, not a minor series, not a patch, and not `.ruby-version`:

```yaml
- uses: ruby/setup-ruby@v1
  with:
    ruby-version: ruby
    bundler-cache: true
```

3. Refresh ruby-build, then set `.ruby-version` to the newest stable `X.Y.Z` it lists. Install that Ruby if it is missing:

```bash
brew upgrade ruby-build
latest="$(ruby-build --definitions | awk 'NF && $1 !~ /-/ && $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+$/ {v=$1} END {print v}')"
rbenv install -s "$latest"
printf '%s\n' "$latest" > .ruby-version
```

4. Always update to the latest stable Jekyll before deploy. Read the current version from RubyGems, set `gem "jekyll"` in the Gemfile to that exact version, then update the lockfile:

```bash
jekyll_version="$(curl -fsSL https://rubygems.org/api/v1/versions/jekyll/latest.json | ruby -rjson -e 'print JSON.parse($stdin.read).fetch("version")')"
JEKYLL_VERSION="$jekyll_version" ruby -i -pe '$_.sub!(/\Agem "jekyll".*/, %(gem "jekyll", "#{ENV.fetch("JEKYLL_VERSION")}"))' Gemfile
bundle update jekyll
```

`latest.json` is the latest stable release. Do not install a prerelease.

5. Confirm `deploy` still `needs: build`, runs only when the event is not `pull_request`, and uses `actions/deploy-pages`.
6. From the repo root, run `bundle exec jekyll build`. Fix a failed build before treating the site as ready to ship.
7. Push or merge to `main` only when the user asked to ship. The workflow deploys on push to `main`.
