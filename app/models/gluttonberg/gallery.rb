module Gluttonberg
  class Gallery < ActiveRecord::Base
    self.table_name = "gb_galleries"
    include Content::SlugManagement
    include Content::Publishable

    attr_accessible :title, :slug, :description, :state, :published_at, :collection_imported
    has_many :gallery_images , :order => "position ASC"
    belongs_to :user

    def name
      title
    end

    def name=(new_name)
      title = new_name
    end

    def images
      gallery_images.map{|i| i.image }
    end

  end
end