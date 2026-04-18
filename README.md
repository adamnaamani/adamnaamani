# Jekyll Website

A personal Jekyll site using the [Minima](https://github.com/jekyll/minima) theme.

## Requirements

- Ruby 3.x (tested with 3.4.6)
- Bundler 2.x

## Getting started

Install dependencies:

```bash
bundle config set --local path 'vendor/bundle'
bundle install
```

Run the development server:

```bash
bundle exec jekyll serve --livereload
```

The site will be available at [http://127.0.0.1:4000](http://127.0.0.1:4000).

## Build for production

```bash
JEKYLL_ENV=production bundle exec jekyll build
```

The generated site will be in the `_site/` directory.

## Structure

- `_config.yml` — site configuration
- `_posts/` — blog posts (`YYYY-MM-DD-title.md`)
- `index.md` — home page
- `about.md` — about page
- `Gemfile` — Ruby dependencies

