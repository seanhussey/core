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
      def create_image_asset
        file = GbFile.new(File.join(RSpec.configuration.fixture_path, "assets/gb_banner.jpg"))
        file.original_filename = "gluttonberg_banner.jpg"
        file.content_type = "image/jpeg"
        file.size = 300
        param = {
          :name=>"temp file",
          :file=> file,
          :description=>"<p>test</p>"
        }
        Gluttonberg::Library.bootstrap
        asset = Asset.new( param )
        asset.save
        asset
      end

      def prepare_content_data(contents, asset)
        contents_data = {}
        contents.each do |content|
          contents_data[content.association_name] = {} unless contents_data.has_key?(content.association_name)
          contents_data[content.association_name][content.id.to_s] = {} unless contents_data[content.association_name].has_key?(content.id.to_s)
          if content.association_name == :image_contents
            contents_data[content.association_name][content.id.to_s][:asset_id] = asset.id
          elsif content.association_name == :plain_text_content_localizations
            contents_data[content.association_name][content.id.to_s][:text] = "Newsletter Title"
          elsif content.association_name == :html_content_localizations
            contents_data[content.association_name][content.id.to_s][:text] = "<p>Newsletter Description</p>"
          end
        end
        contents_data
      end

      def compare_data(contents, asset)
        contents.each do |content|
          if content.association_name == :image_contents
            content.asset_id.should == asset.id
          elsif content.association_name == :plain_text_content_localizations
            content.text.should == "Newsletter Title"
          elsif content.association_name == :html_content_localizations
            content.text.should == "<p>Newsletter Description</p>"
          end
        end
      end

      def compare_easy_contents_data(page, asset)
        page.easy_contents(:title).should == "Newsletter Title"
        page.easy_contents(:description).should == "<p>Newsletter Description</p>"
        page.easy_contents(:image).should == asset.url
        page.easy_contents(:image, :url_for => :fixed_image).should == asset.url_for(:fixed_image)
      end
  end #PageLocalization
end