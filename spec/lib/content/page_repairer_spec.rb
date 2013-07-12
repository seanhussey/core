require 'spec_helper'

module Gluttonberg
  describe Page do

    before(:all) do
      @page = Page.create(:name => 'first name', :description_name => 'generic_page')
      @locale = Gluttonberg::Locale.generate_default_locale
    end

    after(:all) do
      clean_all_data
      PageDescription.clear!
      PageDescription.setup
    end

    it "should repair exiting pages when new section is added to page description" do
      @page.current_localization.contents.length.should == 3
      @page.current_localization.contents[0].parent.section_name.should == "title"
      @page.current_localization.contents[1].parent.section_name.should == "description"
      @page.current_localization.contents[2].section_name.should == "image"
    
      PageDescription[:generic_page].section :image2 do
        label "Image2"
        type  :image_content
      end
      PageDescription[:generic_page].contains_section?(:image2 , :image_content).should == true
      Page.repair_pages_structure
      @page = Page.where(:id => @page.id).first
      @page.current_localization.contents.length.should == 4
      @page.current_localization.contents[3].section_name.should == "image2"
      PageDescription.clear!
      PageDescription.setup
    end

    it "should repair exiting pages when section is deleted from page description" do
      @page.current_localization.contents.length.should == 3
      @page.current_localization.contents[0].parent.section_name.should == "title"
      @page.current_localization.contents[1].parent.section_name.should == "description"
      @page.current_localization.contents[2].section_name.should == "image"
    
      PageDescription[:generic_page].remove_section :image
      PageDescription[:generic_page].contains_section?(:image , :image_content).should == false
      Page.repair_pages_structure
      @page = Page.where(:id => @page.id).first
      @page.current_localization.contents.length.should == 2
      @page.current_localization.contents[0].parent.section_name.should == "title"
      @page.current_localization.contents[1].parent.section_name.should == "description"
      PageDescription.clear!
      PageDescription.setup
    end

    

  end
end