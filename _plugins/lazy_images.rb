module LazyImages
  IMG_TAG = /<img\b([^>]*)>/i

  def self.enhance(html)
    return html if html.nil? || html.empty?

    html.gsub(IMG_TAG) do
      attrs = Regexp.last_match(1)
      attrs = "#{attrs} loading=\"lazy\"" unless attrs =~ /\sloading\s*=/i
      attrs = "#{attrs} decoding=\"async\"" unless attrs =~ /\sdecoding\s*=/i
      "<img#{attrs}>"
    end
  end
end

Jekyll::Hooks.register [:posts, :pages, :documents], :post_render do |doc|
  next unless doc.output_ext == ".html"
  doc.output = LazyImages.enhance(doc.output)
end
