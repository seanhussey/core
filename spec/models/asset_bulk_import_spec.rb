require 'spec_helper'

module Gluttonberg
  describe AssetBulkImport, "Asset bulk import using zip" do
    before :all do
      @file = GbFile.new(File.join(RSpec.configuration.fixture_path, "assets/assets_import.zip"))
      @collection1 = AssetCollection.new(:name => "Collection1")
      @collection2 = AssetCollection.new(:name => "Collection2")
      @asset_collections = [ @collection1 , @collection2 ]
      @param = {
        :asset_collections => @asset_collections,
        :file => @file
      }
      @current_user = User.new
      Gluttonberg::Library.bootstrap
    end

    after :all do
      clean_all_data
    end

    it "should generate all valid assets including subdirectories from zip file" do
      assets = AssetBulkImport.open_zip_file_and_make_assets(@param, @current_user)
      assets.should_not be_nil
      assets.length.should == 3
    end

    it "should assign collections to all valid assets including subdirectories from zip file" do
      assets = AssetBulkImport.open_zip_file_and_make_assets(@param, @current_user)
      assets.should_not be_nil
      assets.each do |asset|
        asset.asset_collections.should == @asset_collections
      end
    end

    it "should return correct number of images for a collection" do
      assets = AssetBulkImport.open_zip_file_and_make_assets(@param, @current_user)
      assets.should_not be_nil
      @collection1.images.should_not be_nil
      @collection1.images.length.should == 2
    end
  end
end