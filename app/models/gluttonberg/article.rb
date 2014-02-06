module Gluttonberg
  class Article < ActiveRecord::Base
    self.table_name = "gb_articles"
    include Content::SlugManagement
    include Content::Publishable
    include Content::Localization

    belongs_to :blog
    belongs_to :author, :class_name => "User"
    belongs_to :user #created by
    has_many :comments, :as => :commentable, :dependent => :destroy
    has_many :localizations, :class_name => "Gluttonberg::ArticleLocalization" , :foreign_key => :article_id  , :dependent => :destroy

    acts_as_taggable_on :article_category , :tag
    attr_accessor :name
    delegate :title , :body , :excerpt , :featured_image_id , :featured_image  , :to => :current_localization
    attr_accessible :user_id, :blog_id, :author_id, :slug, :article_category_list, :tag_list, :disable_comments, :state, :published_at, :name
    attr_accessible :user, :blog, :author
    validates_presence_of :user_id, :author_id, :blog_id
    delegate :version, :loaded_version,  :to => :current_localization

    if ActiveRecord::Base.connection.table_exists?('gb_article_localizations')
      is_localized(:parent_key => :article_id) do
        self.table_name = "gb_article_localizations"
        belongs_to :article  , :class_name => "Gluttonberg::Article"
        belongs_to :locale

        belongs_to :fb_icon , :class_name => "Gluttonberg::Asset" , :foreign_key => "fb_icon_id"
        belongs_to :featured_image , :foreign_key => :featured_image_id , :class_name => "Gluttonberg::Asset"

        is_versioned :non_versioned_columns => ['state' , 'disable_comments' , 'published_at' , 'article_id' , 'locale_id']

        validates_presence_of :title
        attr_accessible :article, :locale_id, :title, :featured_image_id, :excerpt, :body, :seo_title, :seo_keywords, :seo_description, :fb_icon_id, :article_id
        delegate :state, :_publish_status, :state_changed?, :to => :parent

        clean_html [:excerpt , :body]

        def name
          title
        end

        def slug
          self.article.slug
        end
      end #is_localized
    end

    import_export_csv([:id, :slug, :title, :seo_title, :seo_description, :seo_keywords, :state], [:excerpt, :body])

    def commenting_disabled?
      !disable_comments.blank? && disable_comments
    end

    def moderation_required
      if self.blog.blank?
        true
      else
        self.blog.moderation_required
      end
    end

    def current_localization
      if @current_localization.blank?
        load_default_localizations
      end
      @current_localization
    end

    # Load the matching localization as specified in the options
    def load_localization(locale = nil)
      if locale.blank? || locale.id.blank?
        @current_localization = load_default_localizations
      else
        @current_localization = localizations.where("locale_id = ?", locale.id).first
      end
      @current_localization
    end

    def load_default_localizations
      @current_localization = localizations.where(:locale_id => Locale.first_default.id).first
    end

    def create_localizations(params)
      Locale.all.each do |locale|
        article_localization = ArticleLocalization.create(params.merge({
          :locale_id => locale.id, 
          :article_id => self.id
        }))
      end
    end

    def duplicate
      ActiveRecord::Base.transaction do
        duplicated_article = self.dup
        duplicated_article.state = "draft"
        duplicated_article.created_at = Time.now
        duplicated_article.published_at = nil

        if duplicated_article.save
          self.localizations.each do |loc|
            dup_loc = loc.dup
            dup_loc.article_id = duplicated_article.id
            dup_loc.created_at = Time.now
            dup_loc.save
          end
          duplicated_article
        else
          nil
        end
      end
    end

  end
end