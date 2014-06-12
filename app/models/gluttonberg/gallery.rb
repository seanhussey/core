module Gluttonberg
  class Gallery < ActiveRecord::Base
    self.table_name = "gb_galleries"

    include Content::SlugManagement
    include Content::Publishable
    include ActionView::Helpers::TextHelper

    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)

    has_many :gallery_images , :order => "position ASC", :dependent => :destroy
    belongs_to :fb_icon , :class_name => "Gluttonberg::Asset" , :foreign_key => "fb_icon_id"
    belongs_to :user

    attr_accessible :title, :slug, :description, :state, :published_at, :collection_imported
    attr_accessible :gallery_images, :gallery_images_attributes
    accepts_nested_attributes_for :gallery_images, :allow_destroy => true
    attr_accessible :seo_title, :seo_keywords, :seo_description, :fb_icon_id
    
    alias_attribute :name, :title
    validates_presence_of :user_id

    # Array of actual assets
    def images
      gallery_images.map{|i| i.image }
    end

    # Attach all images of a collection to current gallery
    def save_collection_images(params, current_user)
      unless params[:collection_id].blank?
        collection = AssetCollection.where(:id => params[:collection_id]).first
        collection_images = collection.images
        Gluttonberg::Feed.log(current_user,self, self.title , "add #{pluralize(collection_images.length , 'image')} from collection '#{collection.name}'")
        max_position = self.gallery_images.length
        collection_images.each_with_index do |image , index|
          self.gallery_images.create({
            :caption  => image.name,
            :link     => image.link,
            :credits  => image.artist_name,
            :asset_id => image.id,
            :position => (max_position + index)
          })
        end
        self.update_attributes(:collection_imported => true)
      end
    end

  end
end