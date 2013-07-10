module Gluttonberg
  class Article < ActiveRecord::Base
    self.table_name = "gb_articles"
    include Content::SlugManagement
    include Content::Publishable

    belongs_to :blog
    belongs_to :author, :class_name => "User"
    belongs_to :user #created by
    has_many :comments, :as => :commentable, :dependent => :destroy
    has_many :localizations, :class_name => "Gluttonberg::ArticleLocalization" , :foreign_key => :article_id  , :dependent => :destroy

    acts_as_taggable_on :article_category , :tag
    attr_accessor :name
    delegate :title , :body , :excerpt , :featured_image_id , :featured_image  , :to => :current_localization
    attr_accessible :user_id, :blog_id, :author_id, :slug, :article_category_list, :tag_list, :disable_comments, :state, :published_at, :name

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