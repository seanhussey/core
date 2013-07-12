require 'spec_helper'


# this test is considering page_descriptions file in config folder
# and its test is based on newsletter page type
# page :newsletter do
#   label "Newsletter"
#   description "Newsletter Page"
#   view "newsletter"
#   layout "application"
#
#   section :title do
#     label "Title"
#     type :plain_text_content
#   end
#
#   section :description do
#     label "Description"
#     type :html_content
#   end
#
#   section :image do
#     label "Image"
#     type  :image_content
#   end
#
# end


module Gluttonberg
  describe LocaleObserver do

    before(:all) do
      @page = Page.create(:name => 'first name', :description_name => 'generic_page')
      @locale = Gluttonberg::Locale.generate_default_locale
      @observer = LocaleObserver.instance
    end

    after :all do
      clean_all_data
    end


    it "should create localizations for existing pages when we create locale" do
      @page.reload
      @page.localizations.length.should == 1
    end

    it "should create localizations for new pages when we create locale" do
      page2 = Page.create! :name => 'Page2', :description_name => 'generic_page'
      page2.localizations.length.should == 1
    end

    it "should create content localizations for existing pages when we create locale" do
      @page.localizations.first.html_content_localizations.length.should == 1
      @page.localizations.first.plain_text_content_localizations.length.should == 1
    end

    it "should create content localizations for new pages for existing locale(s)" do
      page2 = Page.create! :name => 'Page2', :description_name => 'generic_page'
      page2.localizations.first.html_content_localizations.length.should == 1
      page2.localizations.first.plain_text_content_localizations.length.should == 1
    end

  end
end