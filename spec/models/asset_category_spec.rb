require 'spec_helper'

module Gluttonberg
  describe AssetCategory do

    before :all do
      AssetCategory.build_defaults
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
  end
end