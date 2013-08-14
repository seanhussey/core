# encoding: utf-8

require 'spec_helper'

module Gluttonberg
  describe Public do
    before :all do
      @file = GbFile.new(File.join(RSpec.configuration.fixture_path, "assets/assets_import.zip"))
      @collection1 = AssetCollection.create(:name => "Collection1")
      @collection2 = AssetCollection.create(:name => "Collection2")
      @asset_collections = [ @collection1 , @collection2 ]
      @param = {
        :asset_collections => @asset_collections,
        :file => @file
      }
      @current_user = User.new({
        :first_name => "First",
        :email => "valid_user@test.com",
        :password => "password1",
        :password_confirmation => "password1"
      })
      @current_user.role = "super_admin"
      @current_user.save
      Gluttonberg::Library.bootstrap

      @assets = AssetBulkImport.open_zip_file_and_make_assets(@param, @current_user)
      @assets.should_not be_nil
      @assets.length.should == 3
    end

    after :all do
      clean_all_data
    end

    it "gallery_images_ul" do
      helper.gallery_images_ul(nil, :jwysiwyg_image, :fixed_image).should be_nil
      helper.gallery_images_ul(1, :jwysiwyg_image, :fixed_image).should be_nil

      params = {
        :gluttonberg_gallery => {
          :title => "test",
          :slug => "test",
          :description => "",
          :state => "published",
          :published_at => "2013-08-14 1:24"
        },
        :collection_id => @collection1.id
      }

      @gallery = Gallery.new(params[:gluttonberg_gallery])
      @gallery.user_id = @current_user.id
      @gallery.save
      @gallery.save_collection_images(params, @current_user)

      helper.gallery_images_ul(@gallery.id, :jwysiwyg_image, :fixed_image).scan("<ul>").length.should eql(1)
      helper.gallery_images_ul(@gallery.id, :jwysiwyg_image, :fixed_image).scan("<li").length.should eql(2)
      helper.gallery_images_ul(@gallery.id, :jwysiwyg_image, :fixed_image).scan("</li>").length.should eql(2)
    end



    
  end 
end