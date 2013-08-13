# encoding: utf-8

require 'spec_helper'

module Gluttonberg
  describe Public do
    before :all do
      Gluttonberg::Setting.generate_common_settings
    end

    after :all do
      clean_all_data
    end

    it "keywords tag" do
      Setting.update_settings("keywords" => "website, keywords")
      helper.keywords_meta_tag.should eql("<meta content=\"website, keywords\" name=\"keywords\" />")
      Setting.update_settings("keywords" => nil)
      helper.keywords_meta_tag.should be_nil
    end

    it "description tag" do
      Setting.update_settings("description" => "website description")
      helper.description_meta_tag.should eql("<meta content=\"website description\" name=\"description\" />")
      Setting.update_settings("description" => nil)
      helper.description_meta_tag.should be_nil
    end    
  end 
end