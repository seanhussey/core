require 'spec_helper'

module Gluttonberg
  describe AssetCategory do

    before :all do
      Gluttonberg::Library.bootstrap
    end

    after :all do
      clean_all_data
    end

    it "should have 5 categories" do
      @categories = AssetCategory.all
      @categories.count.should == 5
    end

    it "should have 4 known categories" do
      @categories = AssetCategory.where(:unknown => false)
      @categories.count.should == 4
    end

    it "should have 1 unknown category" do
      @categories = AssetCategory.where(:unknown => true)
      @categories.count.should == 1
    end

    it "should have 1 unknown category named 'uncategorised' " do
      @category = AssetCategory.where(:unknown => true).first
      @category.name.should == "uncategorised"
    end

    it "ensure_exists should update category if already exist" do
      AssetCategory.ensure_exists("image", false)
      AssetCategory.where(:name => "image").count == 1
      AssetCategory.where(:name => "image").first.unknown == false
      AssetCategory.ensure_exists("image", true)
      AssetCategory.where(:name => "image").count == 1
      AssetCategory.where(:name => "image").first.unknown == true
    end

    it "should find assets for category" do
      file = GbFile.new(File.join(RSpec.configuration.fixture_path, "assets/assets_import.zip"))
      current_user = User.new
      param = {
        :file => file
      }
      assets = AssetBulkImport.open_zip_file_and_make_assets(param, current_user)
      assets.should_not be_nil
      AssetCategory.find_assets_by_category("all").count.should == 3
      AssetCategory.find_assets_by_category("").count.should == 3
      AssetCategory.find_assets_by_category("image").count.should == 2
    end

    it "should find assets for category" do
      file = GbFile.new(File.join(RSpec.configuration.fixture_path, "assets/assets_import.zip"))
      current_user = User.new
      collection1 = AssetCollection.new(:name => "Collection1")
      collection2 = AssetCollection.new(:name => "Collection2")
      param = {
        :asset_collections => [collection1],
        :file => file
      }
      assets = AssetBulkImport.open_zip_file_and_make_assets(param, current_user)
      assets.should_not be_nil
      AssetCategory.find_assets_by_category_and_collection("all", collection1).count.should == 3
      AssetCategory.find_assets_by_category_and_collection("", collection1).count.should == 3
      AssetCategory.find_assets_by_category_and_collection("image", collection1).count.should == 2

      AssetCategory.find_assets_by_category_and_collection("all", collection2).count.should == 0
      AssetCategory.find_assets_by_category_and_collection("", collection2).count.should == 0
      AssetCategory.find_assets_by_category_and_collection("image", collection2).count.should == 0
      
    end
  end
end