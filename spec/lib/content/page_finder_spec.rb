require 'spec_helper'

module Gluttonberg
  describe Content::PageFinder do

    before(:all) do
      @page = Page.create(:name => 'first name', :description_name => 'generic_page')
      @locale = Gluttonberg::Locale.generate_default_locale
      @observer = PageLocalizationObserver.instance
      @page2 = Page.create(:name => 'Page2', :description_name => 'generic_page', :parent_id => @page.id)
    end

    after(:all) do
      clean_all_data
    end

    it "should find_by_path using default locale" do
      page = Page.find_by_path("/first-name")
      page.should_not be_nil
      page.id.should == @page.id
      page.current_localization.id.should == @page.current_localization.id
    end

    it "should find_by_path when path have trailing /" do
      page = Page.find_by_path("/first-name/")
      page.should_not be_nil
      page.id.should == @page.id
      page.current_localization.id.should == @page.current_localization.id
    end

    it "should find_by_previous_path using default locale" do
      page = Page.find_by_path("/first-name")
      page.should_not be_nil
      page.id.should == @page.id
      page.current_localization.id.should == @page.current_localization.id
    
      page.current_localization.previous_path = page.current_localization.path
      page.current_localization.slug = "first-name-changed"
      page.current_localization.save

      page = Page.find_by_previous_path("/first-name")
      page.should_not be_nil
      page.id.should == @page.id
      page.current_localization.id.should == @page.current_localization.id

      page = Page.find_by_previous_path("/first-name/")
      page.should_not be_nil
      page.id.should == @page.id
      page.current_localization.id.should == @page.current_localization.id
    end

    it "should find home page using find_by_path and default locale" do
      home_page = Page.create(:name => 'Home', :description_name => 'home', :home => true)
      page = Page.find_by_path("/")
      page.should_not be_nil
      page.id.should == home_page.id
      page.current_localization.id.should == home_page.current_localization.id

      page = Page.find_by_path("")
      page.should_not be_nil
      page.id.should == home_page.id
      page.current_localization.id.should == home_page.current_localization.id

      page = Page.find_by_path("/home")
      page.should_not be_nil
      page.id.should == home_page.id
      page.current_localization.id.should == home_page.current_localization.id
    end

  end
end