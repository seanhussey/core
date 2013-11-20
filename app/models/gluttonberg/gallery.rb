module Gluttonberg
  class Gallery < ActiveRecord::Base
    self.table_name = "gb_galleries"
    include Content::SlugManagement
    include Content::Publishable
    include ActionView::Helpers::TextHelper

    attr_accessible :title, :slug, :description, :state, :published_at, :collection_imported
    has_many :gallery_images , :order => "position ASC", :dependent => :destroy
    attr_accessible :gallery_images, :gallery_images_attributes
    accepts_nested_attributes_for :gallery_images, :allow_destroy => true

    belongs_to :user
    alias_attribute :name, :title
    validates_presence_of :user_id

    def images
      gallery_images.map{|i| i.image }
    end

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