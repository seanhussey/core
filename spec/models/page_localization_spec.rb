require 'spec_helper'

module Gluttonberg
  describe PageLocalization do

    before(:all) do
      @locale = Gluttonberg::Locale.generate_default_locale
      @page = Page.create! :name => 'first name', :description_name => 'newsletter'
      Gluttonberg::Setting.generate_common_settings
    end

    after(:all) do
      Gluttonberg::Page.all.each{|page| page.destroy}
      Gluttonberg::Locale.all.each{|locale| locale.destroy}
      Gluttonberg::Setting.all.each{|setting| setting.destroy}
      Gluttonberg::Library.flush_asset_types
      Gluttonberg::AssetCategory.all.each{|asset_mime_type| asset_mime_type.destroy}
      Gluttonberg::Asset.all.each{|asset| asset.destroy}
    end


    it "contents=, contents and easy_contents should accept and return all content in correct format" do
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

      page_localization = @page.current_localization
      contents = page_localization.contents
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
    
      page_localization.contents = contents_data

      contents.each do |content|
        if content.association_name == :image_contents
          content.asset_id.should == asset.id
        elsif content.association_name == :plain_text_content_localizations
          content.text.should == "Newsletter Title"
        elsif content.association_name == :html_content_localizations
          content.text.should == "<p>Newsletter Description</p>"
        end
      end

      page_localization.save

      @page = Page.where(:id => @page.id).first
      page_localization = @page.current_localization
      contents = page_localization.contents

      contents.each do |content|
        if content.association_name == :image_contents
          content.asset_id.should == asset.id
        elsif content.association_name == :plain_text_content_localizations
          content.text.should == "Newsletter Title"
        elsif content.association_name == :html_content_localizations
          content.text.should == "<p>Newsletter Description</p>"
        end
      end


      @page.easy_contents(:title).should == "Newsletter Title"
      @page.easy_contents(:description).should == "<p>Newsletter Description</p>"
      @page.easy_contents(:image).should == asset.url
      @page.easy_contents(:image, :url_for => :fixed_image).should == asset.url_for(:fixed_image)

    end
  end #PageLocalization
end