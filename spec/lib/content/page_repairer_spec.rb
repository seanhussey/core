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
      @page.current_localization.contents.length.should == 5
      @page.current_localization.contents[0].parent.section_name.should == "title"
      @page.current_localization.contents[1].parent.section_name.should == "description"
      @page.current_localization.contents[2].section_name.should == "image"
      @page.current_localization.contents[3].parent.section_name.should == "excerpt"
      @page.current_localization.contents[4].section_name.should == "theme"
      

      PageDescription[:generic_page].section :image2 do
        label "Image2"
        type  :image_content
      end
      PageDescription[:generic_page].contains_section?(:image2 , :image_content).should == true
      Page.repair_pages_structure
      @page = Page.where(:id => @page.id).first
      @page.current_localization.contents.length.should == 6
      @page.current_localization.contents[5].section_name.should == "image2"
      PageDescription.clear!
      PageDescription.setup
    end

    it "should repair exiting pages when section is deleted from page description" do
      @page.current_localization.contents.length.should == 5
      @page.current_localization.contents[0].parent.section_name.should == "title"
      @page.current_localization.contents[1].parent.section_name.should == "description"
      @page.current_localization.contents[2].section_name.should == "image"
      @page.current_localization.contents[3].parent.section_name.should == "excerpt"
      @page.current_localization.contents[4].section_name.should == "theme"
    
      PageDescription[:generic_page].remove_section :image
      PageDescription[:generic_page].contains_section?(:image , :image_content).should == false
      Page.repair_pages_structure
      @page = Page.where(:id => @page.id).first
      @page.current_localization.contents.length.should == 4
      @page.current_localization.contents[0].parent.section_name.should == "title"
      @page.current_localization.contents[1].parent.section_name.should == "description"
      @page.current_localization.contents[2].parent.section_name.should == "excerpt"
      @page.current_localization.contents[3].section_name.should == "theme"
      PageDescription.clear!
      PageDescription.setup
    end

    it "should repair page structure when page description is changed" do
      page = Page.create(:name => 'first name', :description_name => 'generic_page')

      page.current_localization.contents.length.should == 5
      page.current_localization.contents[0].parent.section_name.should == "title"
      page.current_localization.contents[1].parent.section_name.should == "description"
      page.current_localization.contents[2].section_name.should == "image"
      page.current_localization.contents[3].parent.section_name.should == "excerpt"
      page.current_localization.contents[4].section_name.should == "theme"

      # chagne from generic_page to about 
      PageRepairer.change_page_description(page, :generic_page, :about, {:description_name => 'about'})
      page = Page.where(:id => page.id).first

      page.current_localization.contents.length.should == 1
      page.current_localization.contents[0].parent.section_name.should == "top_content"
      page.current_localization.contents[0].class.name.should == "Gluttonberg::HtmlContentLocalization"
    
      # revert back to generic page form about
      PageRepairer.change_page_description(page, :about, :generic_page, {:description_name => 'generic_page'})
      page = Page.where(:id => page.id).first

      page.current_localization.contents.length.should == 5
      page.current_localization.contents[0].parent.section_name.should == "title"
      page.current_localization.contents[1].parent.section_name.should == "description"
      page.current_localization.contents[2].section_name.should == "image"
      page.current_localization.contents[3].parent.section_name.should == "excerpt"
      page.current_localization.contents[4].section_name.should == "theme"

      #change to same type
      PageRepairer.change_page_description(page, :generic_page, :generic_page, {:description_name => 'generic_page'})
      page = Page.where(:id => page.id).first

      page.current_localization.contents.length.should == 5
      page.current_localization.contents[0].parent.section_name.should == "title"
      page.current_localization.contents[1].parent.section_name.should == "description"
      page.current_localization.contents[2].section_name.should == "image"
      page.current_localization.contents[3].parent.section_name.should == "excerpt"
      page.current_localization.contents[4].section_name.should == "theme"

      #change to home
      PageRepairer.change_page_description(page, :generic_page, :home, {:description_name => 'home'})
      page = Page.where(:id => page.id).first

      page.current_localization.contents.length.should == 0
      


      #change to redirect_to_remote
      PageRepairer.change_page_description(page, :home, :redirect_to_remote, {:description_name => 'redirect_to_remote'})
      page = Page.where(:id => page.id).first

      page.current_localization.contents.length.should == 0

      # chagne from redirect_to_remote to about 
      PageRepairer.change_page_description(page, :redirect_to_remote, :about, {:description_name => 'about'})
      page = Page.where(:id => page.id).first

      page.current_localization.contents.length.should == 1
      page.current_localization.contents[0].parent.section_name.should == "top_content"
      page.current_localization.contents[0].class.name.should == "Gluttonberg::HtmlContentLocalization"
      
      #change to redirect_to_path
      PageRepairer.change_page_description(page, :about, :redirect_to_path, {:description_name => 'redirect_to_path'})
      page = Page.where(:id => page.id).first

      page.current_localization.contents.length.should == 0
    end

    it "should pass content to new page description if content name is same" do
      page = Page.create(:name => 'first name', :description_name => 'about')
      page.current_localization.contents.first.update_attributes(:text => "Top Content Text")

      #reload object
      page = Page.where(:id => page.id).first
      page.current_localization.contents[0].parent.section_name.should == "top_content"
      page.current_localization.contents[0].text.should == "Top Content Text"

      PageRepairer.change_page_description(page, :about, :about2, {:description_name => 'about2'})
      page = Page.where(:id => page.id).first

      page.current_localization.contents.length.should == 2
      page.current_localization.contents[0].parent.section_name.should == "left_content"
      page.current_localization.contents[1].parent.section_name.should == "top_content"

      page.current_localization.contents[0].text.should == nil
      page.current_localization.contents[1].text.should == "Top Content Text"

    end

  end
end