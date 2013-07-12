require 'spec_helper'

module Gluttonberg
  describe AssetType do

    before :all do
      Gluttonberg::Library.bootstrap
    end

    after :all do
      clean_all_data
    end

    it "should have 52 gluttonberg asset types" do
      AssetType.count.should == 52
    end

    it "should be able to detect MPEG audio asset type" do
      asset_type = AssetType.for_file("audio/mp3","sample1.mp3")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Mpeg Audio (mpga,mp2,mp3,mp4,mpa)").first
    end

    it "should be able to detect Wave audio asset type" do
      asset_type = AssetType.for_file("audio/x-wav","sample1.wav")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Wav Audio (wav)").first
    end

    it "should be able to detect jpg image asset type" do
      asset_type = AssetType.for_file("image/jpeg","sample1.jpg")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Jpeg Image").first
    end

    it "should be able to detect jpeg image asset type" do
      asset_type = AssetType.for_file("image/jpeg","sample1.jpeg")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Jpeg Image").first
    end

    it "should be able to detect png image asset type" do
      asset_type = AssetType.for_file("image/png","sample1.png")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Png Image").first
    end

    it "should be able to detect bmp image asset type" do
      asset_type = AssetType.for_file("image/x-bmp","sample1.bmp")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Bitmap Image").first
    end

    it "should be able to detect mp4 video asset type" do
      asset_type = AssetType.for_file("video/mp4","sample1.mp4")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Compressed Video").first
    end

    it "should be able to detect mp4 video asset type" do
      asset_type = AssetType.for_file("video/mp4","sample1.mp4")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Compressed Video").first
    end

    it "should be able to detect asset type if mime type is missing but valid file extension is provided" do
      asset_type = AssetType.for_file("","sample1.mp3")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Mpeg Audio (mpga,mp2,mp3,mp4,mpa)").first
    end

    it "should be able to detect asset type if valid mime type (mp4) is provided but file extension is missing" do
      asset_type = AssetType.for_file("audio/mp4","sample1")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Mpeg Audio (mpga,mp2,mp3,mp4,mpa)").first
    end

    it "should be able to detect asset type if valid mime type (mp3) is provided but file extension is missing" do
      asset_type = AssetType.for_file("audio/mp3","sample1")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Mpeg Audio (mpga,mp2,mp3,mp4,mpa)").first
    end

    it "should be able to assign unknown audio type if mime type's first  part is 'audio' but file extension is missing" do
      asset_type = AssetType.for_file("audio/mp3333","sample1")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Unknown Audio").first
    end

    it "should assign unknown asset type if mime type is missing and invalid file extension is provided" do
      asset_type = AssetType.for_file("","sample1.mpppp3")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Unknown File").first
    end

    it "should assign unknown asset type if mime type and file extension are missing" do
      asset_type = AssetType.for_file("","sample1")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Unknown File").first
    end

    it "should assign unknown asset type if mime type and file name are missing" do
      asset_type = AssetType.for_file("","")
      asset_type.blank?.should == false
      asset_type.should == AssetType.where(:name => "Unknown File").first
    end

  end
end