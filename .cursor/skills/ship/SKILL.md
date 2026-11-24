---
name: ship
description: >-
  Ship this Jekyll site to GitHub Pages on the latest stable Ruby.
  Use when deploying, shipping, pushing to main, editing
  .github/workflows/pages.yml, changing .ruby-version, or when a
  ruby/setup-ruby job fails with an unavailable Ruby version.
---

# Ship

Deploy is `.github/workflows/pages.yml`. Always update to the latest stable Ruby before shipping. `ubuntu-latest` only has the latest patch of each series, so a stale patch in `ruby-version` makes `ruby/setup-ruby` return HTTP 404 and the build never starts.

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

4. Confirm `deploy` still `needs: build`, runs only when the event is not `pull_request`, and uses `actions/deploy-pages`.
5. From the repo root, run `bundle exec jekyll build`. Fix a failed build before treating the site as ready to ship.
6. Push or merge to `main` only when the user asked to ship. The workflow deploys on push to `main`.
