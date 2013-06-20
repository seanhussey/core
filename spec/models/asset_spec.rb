require 'spec_helper'

# i have added some attributes to file class.
# because rails adds these attributes when file is uploaded through form.
class File
  attr_accessor :original_filename  , :content_type , :size

  def tempfile
    self
  end
end


module Gluttonberg

  describe Asset, "file upload" do

    before :all do
      @file = File.new(File.join(RSpec.configuration.fixture_path, "assets/gluttonberg_logo.jpg"))
      @file.original_filename = "gluttonberg_logo.jpg"
      @file.content_type = "image/jpeg"
      @file.size = 300

      @collection1 = AssetCollection.new(:name => "Collection1")
      @collection2 = AssetCollection.new(:name => "Collection2")
      @collection3 = AssetCollection.new(:name => "Collection3")

      @param = {
          :name=>"temp file",
          :asset_collections => [ @collection1 , @collection3 ],
          :file=> @file,
          :description=>"<p>test</p>"
      }

      Gluttonberg::Library.bootstrap

      @asset = Asset.new( @param )

    end

    it "should generate filename" do
      @asset.file_name.should_not be_nil
    end

    it "should format filename correctly" do
      @asset.file_name.should == "gluttonberg_logo.jpg"
    end

    it "should set size" do
      @asset.size.should_not be_nil
    end

    it "should set type name" do
      @asset.valid?
      @asset.type_name.should_not be_nil
    end

    it "should set category" do
      @asset.valid?
      @asset.category.should_not be_nil
    end

    it "should set the correct type" do
      @asset.valid?
      @asset.type_name.should == "Jpeg Image"
    end

    it "should set the correct category" do
      @asset.valid?
      @asset.category.should == "image"
    end

    it "should set the correct collection" do
      @asset.valid?
      @asset.asset_collections.first.name.should == "Collection1"
      @asset.asset_collections[1].name.should == "Collection3"
    end

    it "should clean its garbage (asset directory is deleted) when asset is actually deleted." do
      asset = Asset.new( @param )
      status = asset.save
      status.should == true
      url = asset.url
      location_on_disk = asset.location_on_disk
      directory = asset.directory
      File.exists?(location_on_disk).should == true
      File.exists?(directory).should == true
      asset.destroy
      File.exists?(location_on_disk).should == false
      File.exists?(directory).should == false
    end

    # thumbnails
    it "should generate all thumbnails when image asset is saved." do
      asset = Asset.new( @param )
      status = asset.save
      status.should == true
      File.exists?(asset.location_on_disk).should == true
      asset.class.sizes.each_pair do |name, config|
        File.exists?(File.join(asset.directory, "#{config[:filename]}.#{asset.file_extension}")).should == true
      end
      asset.destroy
    end

    it "should generate original_ image (by duplicating user's uploaded image) when generating thumbnails" do
      asset = Asset.new( @param )
      status = asset.save
      status.should == true
      File.exist?(asset.original_file_on_disk).should == true
      asset.destroy
    end

  end
end