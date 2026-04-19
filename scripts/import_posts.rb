#!/usr/bin/env ruby

require "bundler/setup"
require "json"
require "yaml"
require "fileutils"
require "time"
require "reverse_markdown"

POSTS_JSON = ENV.fetch("POSTS_JSON", "/Users/adamnaamani/Documents/Backups/posts.json")
RICH_JSON  = ENV.fetch("RICH_JSON",  "/Users/adamnaamani/Documents/Backups/action_text_rich_texts.json")
OUT_DIR    = ENV.fetch("OUT_DIR",    File.expand_path("../_posts", __dir__))

FileUtils.mkdir_p(OUT_DIR)

posts = JSON.parse(File.read(POSTS_JSON))
rich  = JSON.parse(File.read(RICH_JSON))

content_by_post = rich
  .select { |r| r["record_type"] == "Post" && r["name"] == "content" }
  .each_with_object({}) { |r, h| h[r["record_id"]] = r["body"].to_s }

def parse_date(str)
  Time.parse(str)
rescue ArgumentError, TypeError
  nil
end

def html_to_markdown(html)
  cleaned = html.dup
  cleaned.gsub!(/<b>\s*<strong>(.*?)<\/strong>\s*<\/b>/m, '<strong>\1</strong>')
  cleaned.gsub!(/<strong>\s*<b>(.*?)<\/b>\s*<\/strong>/m, '<strong>\1</strong>')
  cleaned.gsub!(/<i>\s*<em>(.*?)<\/em>\s*<\/i>/m, '<em>\1</em>')
  cleaned.gsub!(/<em>\s*<i>(.*?)<\/i>\s*<\/em>/m, '<em>\1</em>')
  cleaned.gsub!("&nbsp;", " ")

  md = ReverseMarkdown.convert(
    cleaned,
    unknown_tags: :bypass,
    github_flavored: true
  )

  md.gsub!(/(\*\*|__|\*|_)\s+([,.;:!?\)\]])/, '\1\2')
  md.gsub!(/([\(\[])\s+(\*\*|__|\*|_)/, '\1\2')
  md.gsub!(/\A\s+/, "")
  md.gsub!(/[ \t]+$/, "")
  md.gsub!(/\n{3,}/, "\n\n")
  md.strip + "\n"
end

written = 0
skipped = 0

posts.each do |post|
  id        = post["id"]
  title     = post["title"].to_s
  slug      = post["slug"].to_s.strip
  meta      = post["meta"] || {}
  desc      = meta.is_a?(Hash) ? meta["description"].to_s : ""
  status    = post["status"]
  published = parse_date(post["published_date"]) || parse_date(post["created_at"])
  html      = content_by_post[id]

  if slug.empty? || published.nil? || html.nil?
    warn "skip id=#{id} (missing slug/date/body)"
    skipped += 1
    next
  end

  front = {
    "layout"      => "post",
    "title"       => title,
    "date"        => published.strftime("%Y-%m-%d %H:%M:%S %z").sub(/\s$/, " -0800"),
    "slug"        => slug,
    "description" => desc
  }
  front["published"] = false if status != 1

  body = html_to_markdown(html)
  body = "{% raw %}\n#{body.chomp}\n{% endraw %}\n" if body.match?(/\{\{|\{%/)

  file = File.join(OUT_DIR, "#{published.strftime('%Y-%m-%d')}-#{slug}.md")
  File.open(file, "w") do |f|
    f.write(front.to_yaml.sub(/\A---\n/, "---\n"))
    f.write("---\n\n")
    f.write(body)
  end
  written += 1
end

puts "wrote #{written} posts to #{OUT_DIR} (skipped #{skipped})"
