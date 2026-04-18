#!/usr/bin/env ruby

require "json"
require "yaml"
require "fileutils"
require "open3"
require "date"

ATTACHMENTS_JSON = ENV.fetch("ATTACHMENTS_JSON", File.expand_path("~/Documents/Backups/active_storage_attachments.json"))
BLOBS_JSON       = ENV.fetch("BLOBS_JSON",       File.expand_path("~/Documents/Backups/active_storage_blobs.json"))
POSTS_DIR        = ENV.fetch("POSTS_DIR",        File.expand_path("../_posts", __dir__))
IMAGES_DIR       = ENV.fetch("IMAGES_DIR",       File.expand_path("../assets/images/posts", __dir__))
S3_BUCKET        = ENV.fetch("S3_BUCKET",        "adamnaamani")
S3_REGION        = ENV.fetch("S3_REGION",        "ca-central-1")
DRY_RUN          = ENV["DRY_RUN"] == "1"

def load_blobs(path)
  JSON.parse(File.read(path)).each_with_object({}) { |b, h| h[b["id"]] = b }
end

def first_attachment_per_post(path)
  attachments = JSON.parse(File.read(path)).select { |a| a["record_type"] == "Post" }
  attachments
    .group_by { |a| a["record_id"] }
    .transform_values { |rows| rows.min_by { |a| a["id"] } }
end

def index_posts(dir)
  index = {}
  Dir.glob(File.join(dir, "*.md")).each do |path|
    raw = File.read(path)
    next unless raw.start_with?("---\n")

    _, header, body = raw.split(/^---\s*\n/, 3)
    next if header.nil? || body.nil?

    begin
      front = YAML.safe_load(header, permitted_classes: [Time, Date], aliases: false) || {}
    rescue Psych::SyntaxError => e
      warn "skip #{path}: yaml error #{e.message}"
      next
    end

    original_id = front["original_id"]
    slug        = front["slug"].to_s.strip
    next if original_id.nil? || slug.empty?

    index[original_id] = { path: path, slug: slug, front: front, body: body }
  end
  index
end

def download(key, dest)
  tmp = "#{dest}.part"
  FileUtils.rm_f(tmp)
  cmd = ["aws", "s3", "cp", "s3://#{S3_BUCKET}/#{key}", tmp, "--region", S3_REGION, "--only-show-errors"]
  _out, err, status = Open3.capture3(*cmd)
  unless status.success?
    FileUtils.rm_f(tmp)
    raise err.strip.empty? ? "aws s3 cp failed (#{status.exitstatus})" : err.strip
  end
  File.rename(tmp, dest)
end

def dump_front_matter(front)
  yaml = front.to_yaml
  yaml.sub(/\A---\s*\n/, "")
end

def update_post(post, image_path)
  front = post[:front].dup
  front["image"] = image_path
  front["cover"] = image_path

  new_content = +"---\n"
  new_content << dump_front_matter(front)
  new_content << "---\n\n"
  new_content << post[:body].sub(/\A\s*\n/, "")

  File.write(post[:path], new_content)
end

def run
  unless File.exist?(ATTACHMENTS_JSON)
    abort "missing ATTACHMENTS_JSON: #{ATTACHMENTS_JSON}"
  end
  unless File.exist?(BLOBS_JSON)
    abort "missing BLOBS_JSON: #{BLOBS_JSON}"
  end

  puts "attachments: #{ATTACHMENTS_JSON}"
  puts "blobs:       #{BLOBS_JSON}"
  puts "posts dir:   #{POSTS_DIR}"
  puts "images dir:  #{IMAGES_DIR}"
  puts "s3 bucket:   #{S3_BUCKET} (#{S3_REGION})"
  puts "dry run:     #{DRY_RUN}"
  puts

  blobs_by_id  = load_blobs(BLOBS_JSON)
  firsts       = first_attachment_per_post(ATTACHMENTS_JSON)
  posts_by_oid = index_posts(POSTS_DIR)

  downloaded = 0
  skipped    = 0
  failed     = 0
  updated    = 0
  missing    = 0

  firsts.keys.sort.each do |record_id|
    attachment = firsts[record_id]
    blob = blobs_by_id[attachment["blob_id"]]
    unless blob
      warn "post #{record_id}: missing blob id=#{attachment["blob_id"]}"
      missing += 1
      next
    end

    post = posts_by_oid[record_id]
    unless post
      warn "post #{record_id}: no matching _posts/*.md (blob=#{blob["filename"]})"
      missing += 1
      next
    end

    slug     = post[:slug]
    filename = blob["filename"].to_s
    if filename.empty?
      warn "post #{record_id}: blob #{blob["id"]} has no filename"
      failed += 1
      next
    end

    dir      = File.join(IMAGES_DIR, slug)
    dest     = File.join(dir, filename)
    rel_path = "/assets/images/posts/#{slug}/#{filename}"
    key      = blob["key"].to_s

    if File.exist?(dest) && File.size(dest) > 0
      puts "skip #{rel_path} (exists)"
      skipped += 1
    else
      if DRY_RUN
        puts "would download s3://#{S3_BUCKET}/#{key} -> #{rel_path}"
      else
        begin
          FileUtils.mkdir_p(dir)
          download(key, dest)
          puts "downloaded #{rel_path} (#{blob["content_type"]})"
          downloaded += 1
        rescue => e
          warn "post #{record_id}: download failed s3://#{S3_BUCKET}/#{key}: #{e.message}"
          failed += 1
          next
        end
      end
    end

    if post[:front]["image"] == rel_path && post[:front]["cover"] == rel_path
      next
    end

    if DRY_RUN
      puts "would update front matter for #{File.basename(post[:path])} -> image/cover = #{rel_path}"
    else
      update_post(post, rel_path)
      updated += 1
    end
  end

  puts
  puts "summary:"
  puts "  downloaded: #{downloaded}"
  puts "  skipped:    #{skipped}"
  puts "  failed:     #{failed}"
  puts "  updated:    #{updated}"
  puts "  missing:    #{missing}"
end

run
