#require File.dirname(__FILE__) + '/../spec_helper'
require 'spec_helper'

module Gluttonberg

  describe AssetCollection do

    before :all do
      AssetCollection.delete_all
    end

    it "should have 2 collections" do
      AssetCollection.create(:name => "Collection1")
      AssetCollection.create(:name => "Collection2")
      AssetCollection.count.should == 2
    end


    it "should not create collection without name" do
      AssetCollection.create(:name => "")
      @collections = AssetCollection.all
      AssetCollection.count.should == 0
    end

    it "should not create duplicate collection" do
      AssetCollection.create(:name => "Collection1")
      begin
        AssetCollection.create(:name => "Collection1")
      rescue
      end
      @collections = AssetCollection.where(:name => "Collection1")
      @collections.count.should == 1
    end

    it "should clean its associations when collection is deleted"


  end

end