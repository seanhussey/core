xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @blog.name
    xml.description @blog.description
    xml.link blog_url(@blog.slug)

    for article in @articles
      xml.item do
        xml.title article.title
        xml.description article.excerpt || article.body
        xml.pubDate article.created_at.to_s(:rfc822)
        unless article.featured_image.blank?
          xml.image (article.featured_image.url)
        end
        xml.link blog_article_url(:blog_id => @blog.slug, :id => article.slug)
        xml.guid blog_article_url(:blog_id => @blog.slug, :id => article.slug)
      end
    end
  end
end
