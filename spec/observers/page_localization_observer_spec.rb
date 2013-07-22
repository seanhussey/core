require 'spec_helper'


# this test is considering page_descriptions file in config folder
# and its test is based on generic page type
# page :generic_page do
#   label "Generic"
#   description "Generic Page"
#   view "generic"
#   layout "public"

#   section :title do
#     label "Title"
#     type :plain_text_content
#   end

#   section :description do
#     label "Description"
#     type :html_content
#   end

#   section :image do
#     label "Image"
#     type  :image_content
#   end

# end


module Gluttonberg
  describe PageLocalizationObserver do

    before(:all) do
      @page = Page.create(:name => 'first name', :description_name => 'generic_page')
      @locale = Gluttonberg::Locale.generate_default_locale
      @observer = PageLocalizationObserver.instance
      @page2 = Page.create(:name => 'Page2', :description_name => 'generic_page', :parent_id => @page.id)
    end

    after(:all) do
      clean_all_data
    end

    it "should recache path for children localization when we change path for parent page" do
      @page.reload
      @page.path.should == "first-name"
      @page.current_localization.path.should == "first-name"
      @page2.path.should == "first-name/page2"
      @page2.parent_id.should == @page.id
      @page2.current_localization.path.should == "first-name/page2"

      @page.current_localization.slug = "first-name-changed"
      @page.current_localization.save
      
      @page.reload
      @page.current_localization.reload

      @page2.reload
      @page2.current_localization.reload

      @page.path.should == "first-name-changed"
      @page.current_localization.path.should == "first-name-changed"
      @page2.current_localization.path.should == "first-name-changed/page2"

      @page.current_localization.paths_need_recaching = true
      @observer.after_save(@page.current_localization)
      @page2.reload
      @page2.current_localization.reload
      @page2.current_localization.path.should == "first-name-changed/page2"
    end

    
  end
end