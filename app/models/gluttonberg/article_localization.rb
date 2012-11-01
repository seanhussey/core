module Gluttonberg
  class ArticleLocalization < ActiveRecord::Base
    self.table_name = "gb_article_localizations"
    belongs_to :article  , :class_name => "Gluttonberg::Article"
    belongs_to :locale

    belongs_to :fb_icon , :class_name => "Gluttonberg::Asset" , :foreign_key => "fb_icon_id"
    belongs_to :featured_image , :foreign_key => :featured_image_id , :class_name => "Gluttonberg::Asset"

    is_versioned :non_versioned_columns => ['state' , 'disable_comments' , 'published_at' , 'article_id' , 'locale_id']

    validates_presence_of :title
    attr_accessible :article, :locale_id, :title, :featured_image_id, :excerpt, :body, :seo_title, :seo_keywords, :seo_description, :fb_icon_id, :article_id

    clean_html [:excerpt , :body]

    def name
      title
    end
  end
end