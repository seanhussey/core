require 'spec_helper'

module Gluttonberg
  describe PageDescription do

    before :all do
      @locale = Gluttonberg::Locale.generate_default_locale
    end

    after :all do
      clean_all_data
    end

    it "top_level_page?" do
      Gluttonberg::PageDescription.add do
        page :top_level_page do
          label "top level page"
          description "Site Map"
          view "top_level_page"
          layout "public"
        end
      end

      PageDescription[:top_level_page].top_level_page? == true
      PageDescription[:about].top_level_page? == true

      PageDescription.clear!
      PageDescription.all.length.should == 0
      PageDescription.setup
      PageDescription.all.length.should == 6
    end
    
    it "behaviour(name)" do
      rewrite_descriptions = PageDescription.behaviour(:rewrite) 
      rewrite_descriptions.length.should == 1
      rewrite_descriptions.first.rewrite_route == "examples"

      redirect_to_descriptions = PageDescription.behaviour(:redirect) 
      redirect_to_descriptions.length.should == 2

      redirect_to_descriptions = PageDescription.behaviour(:default) 
      redirect_to_descriptions.length.should == 3
    end

    it "names_for()" do
      rewrite_descriptions = PageDescription.names_for(:rewrite) 
      rewrite_descriptions.length.should == 1
      rewrite_descriptions.first.should == :examples

      redirect_to_descriptions = PageDescription.names_for(:redirect) 
      redirect_to_descriptions.length.should == 2
      redirect_to_descriptions.include?(:redirect_to_remote).should == true
      redirect_to_descriptions.include?(:redirect_to_path).should == true

      redirect_to_descriptions = PageDescription.names_for(:default) 
      redirect_to_descriptions.length.should == 3
    end

    it "contain sections" do
      PageDescription[:generic_page].contains_section?(:title , :plain_content).should == false
      PageDescription[:generic_page].contains_section?(:title , :plain_text_content).should == true
      PageDescription[:generic_page].contains_section?(:description , :html_content).should == true
      PageDescription[:generic_page].contains_section?(:image , :image_content).should == true
    end


  end
end