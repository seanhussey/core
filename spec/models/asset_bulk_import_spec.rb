require 'spec_helper'

# # i have added some attributes to file class.
# # because rails adds these attributes when file is uploaded through form.
# class File
#   attr_accessor :original_filename  , :content_type , :size

#   def tempfile
#     self
#   end
# end


module Gluttonberg

  describe AssetBulkImport, "file upload" do

    before :all do
      @file = File.new(File.join(RSpec.configuration.fixture_path, "assets/assets_import.zip"))
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
      Gluttonberg::Library.flush_asset_types
      Gluttonberg::AssetCategory.all.each{|asset_mime_type| asset_mime_type.destroy}
      Gluttonberg::Asset.each{|asset| asset.destroy}
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
        asset.asset_collections == @asset_collections
      end
    end
  end
end