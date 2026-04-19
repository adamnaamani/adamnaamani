require "fastimage"

module LazyImages
  IMG_TAG = /<img\b([^>]*)>/i
  SRC_ATTR = /\ssrc\s*=\s*(?:"([^"]*)"|'([^']*)')/i
  DIMENSION_CACHE = {}

  def self.dimensions_for(src, site)
    return nil if src.nil? || src.empty?
    return nil if src.start_with?("data:")
    return nil if src =~ %r{\A(?:https?:)?//}

    relative = src.dup
    baseurl = site.config["baseurl"].to_s
    relative = relative.sub(/\A#{Regexp.escape(baseurl)}/, "") unless baseurl.empty?
    relative = relative.sub(%r{\A/}, "")

    path = File.join(site.source, relative)

    unless DIMENSION_CACHE.key?(path)
      DIMENSION_CACHE[path] =
        if File.file?(path)
          begin
            FastImage.size(path)
          rescue => e
            Jekyll.logger.warn "LazyImages:", "Could not read size for #{path}: #{e.message}"
            nil
          end
        end
    end

    DIMENSION_CACHE[path]
  end

  def self.enhance(html, site)
    return html if html.nil? || html.empty?

    html.gsub(IMG_TAG) do
      attrs = Regexp.last_match(1)
      match = attrs.match(SRC_ATTR)
      src = match && (match[1] || match[2])

      attrs = "#{attrs} loading=\"lazy\"" unless attrs =~ /\sloading\s*=/i
      attrs = "#{attrs} decoding=\"async\"" unless attrs =~ /\sdecoding\s*=/i

      if src && attrs !~ /\swidth\s*=/i && attrs !~ /\sheight\s*=/i
        dims = dimensions_for(src, site)
        if dims
          w, h = dims
          attrs = "#{attrs} width=\"#{w}\" height=\"#{h}\""
        end
      end

      "<img#{attrs}>"
    end
  end
end

Jekyll::Hooks.register [:posts, :pages, :documents], :post_render do |doc|
  next unless doc.output_ext == ".html"
  doc.output = LazyImages.enhance(doc.output, doc.site)
end
