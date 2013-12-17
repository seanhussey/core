require 'spec_helper'

module Gluttonberg
  describe PageLocalization do

    before(:all) do
      @locale = Gluttonberg::Locale.generate_default_locale
      @page = Page.create! :name => 'first name', :description_name => 'generic_page'
      Gluttonberg::Setting.generate_common_settings
    end

    after(:all) do
      clean_all_data
    end


    it "contents=, contents and easy_contents should accept and return all content in correct format" do
      asset  = create_image_asset
      page_localization = @page.current_localization
      contents = page_localization.contents
    
      page_localization.contents = prepare_content_data(contents, asset)

      # data comparison before save
      compare_data(contents, asset)

      page_localization.save

      @page = Page.where(:id => @page.id).first

      #compare data after save
      compare_data(@page.current_localization.contents, asset)
      compare_easy_contents_data(@page, asset)
    end

    it "duplicate should duplicate all content of a page" do
      page = Page.create! :name => 'first name 2', :description_name => 'generic_page'
      asset  = create_image_asset
    
      page.current_localization.contents = prepare_content_data(page.current_localization.contents, asset)

      page.current_localization.save
      # data comparison before save
      compare_data(page.current_localization.contents, asset)

      page = Page.where(:id => page.id).first
      #compare data after save
      compare_data(page.current_localization.contents, asset)
      
      duplicated = page.duplicate
      compare_data(duplicated.current_localization.contents, asset)
    end

    private

      def compare_data(contents, asset)
        contents.each do |content|
          if content.association_name == :image_contents
            content.asset_id.should == asset.id
          elsif content.association_name == :plain_text_content_localizations
            content.text.should == "Newsletter Title"
          elsif content.association_name == :html_content_localizations
            content.text.should == "<p>Newsletter Description</p>"
          elsif content.association_name == :textarea_content_localizations
            content.text.should == "Newsletter Excerpt"
          elsif content.association_name == :select_contents
            content.text.should == "Theme 1"
          end
        end
      end

      def compare_easy_contents_data(page, asset)
        page.easy_contents(:title).should == "Newsletter Title"
        page.easy_contents(:description).should == "<p>Newsletter Description</p>"
        page.easy_contents(:image).should == asset.url
        page.easy_contents(:image, :url_for => :fixed_image).should == asset.url_for(:fixed_image)
        page.easy_contents(:excerpt).should == "Newsletter Excerpt"
        page.easy_contents(:theme).should == "Theme 1"
      end
  end #PageLocalization
end