module Gluttonberg
  class Blog < ActiveRecord::Base
    self.table_name = "gb_blogs"
    include Content::Publishable
    include Content::SlugManagement

    belongs_to :user
    has_many :articles, :dependent => :destroy

    validates_presence_of :name, :user_id

    is_versioned :non_versioned_columns => ['state' ,'published_at' , 'moderation_required' ]

    acts_as_taggable_on :tag
    clean_html [:description]
    attr_accessible :user_id, :name, :slug, :description, :moderation_required
    attr_accessible :user
    attr_accessible :seo_title, :seo_keywords, :seo_description, :fb_icon_id, :state, :published_at

  end
end