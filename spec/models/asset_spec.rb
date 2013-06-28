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
      @file = File.new(File.join(RSpec.configuration.fixture_path, "assets/gb_banner.jpg"))
      @file.original_filename = "gluttonberg_banner.jpg"
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

    after :all do
      Gluttonberg::Library.flush_asset_types
      Gluttonberg::AssetCategory.all.each{|asset_mime_type| asset_mime_type.destroy}
    end

    it "should generate filename" do
      @asset.file_name.should_not be_nil
    end

    it "should format filename correctly" do
      @asset.file_name.should == "gluttonberg_banner.jpg"
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

    #garbage collection
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

    #backup
    it "should generate original_ image (by duplicating user's uploaded image) when generating thumbnails" do
      asset = Asset.new( @param )
      status = asset.save
      status.should == true
      File.exist?(asset.original_file_on_disk).should == true
      asset.destroy
    end

    # thumbnails
    it "should have all thumbnail settings" do
      Asset.sizes.length.should == 9

    end

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

    # actual image should be resized if large than 1600x1200
    it "should resize actual image if larger than 1600x1200>" do
      file = File.new(File.join(RSpec.configuration.fixture_path, "assets/high_res_photo.jpg"))
      file.original_filename = "high_res_photo.jpg"
      file.content_type = "image/jpeg"
      file.size = 3333287

      asset = Asset.new( @param.merge(:file =>  file) )
      status = asset.save
      status.should == true
      File.exist?(asset.original_file_on_disk).should == true

      image = Library::QuickMagick::Image.read(asset.original_file_on_disk).first
      original_width = image.width.to_i
      original_height = image.height.to_i

      image = Library::QuickMagick::Image.read(asset.location_on_disk).first
      image.width.to_i.should == 1600
      image.height.to_i.should == 1200
      asset.destroy
    end

    # FIXED size thumbnails

    it "should generate fixed size image 1000x1000# when image is larger than required size" do
      file = File.new(File.join(RSpec.configuration.fixture_path, "assets/high_res_photo.jpg"))
      file.original_filename = "high_res_photo.jpg"
      file.content_type = "image/jpeg"
      file.size = 3333287

      asset = Asset.new( @param.merge(:file =>  file) )
      status = asset.save
      status.should == true
      File.exist?(asset.location_on_disk).should == true
      thumb_path = File.join(asset.directory, "fixed_image.jpg")
      File.exists?(thumb_path).should == true

      image = Library::QuickMagick::Image.read(thumb_path).first
      image.width.to_i.should == 1000
      image.height.to_i.should == 1000

      asset.destroy
    end

    # audio
    it "should obtain and save mp3 title" do
      file = File.new(File.join(RSpec.configuration.fixture_path, "assets/audio.mp3"))
      file.original_filename = "audio.mp3"
      file.content_type = "audio/mp3"
      file.size = 1024*1024*1.7

      asset = Asset.new( @param.merge(:file =>  file) )
      status = asset.save
      status.should == true
      File.exist?(asset.location_on_disk).should == true

      asset.audio_asset_attribute.should_not be_nil
      asset.audio_asset_attribute.title.should == "audio"
      asset.destroy
    end

    it "should obtain and save mp3 info" do
      file = File.new(File.join(RSpec.configuration.fixture_path, "assets/audio.mp3"))
      file.original_filename = "audio.mp3"
      file.content_type = "audio/mp3"
      file.size = 1024*1024*1.7

      asset = Asset.new( @param.merge(:file =>  file) )
      status = asset.save
      status.should == true
      File.exist?(asset.location_on_disk).should == true

      asset.audio_asset_attribute.should_not be_nil
      asset.audio_asset_attribute.length.to_i.should == 65
      asset.audio_asset_attribute.artist.should == "Artist Name"
      asset.audio_asset_attribute.tracknum.to_i.should == 3
      asset.destroy
    end


  end
end