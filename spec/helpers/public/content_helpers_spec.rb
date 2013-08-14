# encoding: utf-8

require 'spec_helper'

module Gluttonberg
  describe Public do
    before :all do
      Gluttonberg::Setting.generate_common_settings
      @file = GbFile.new(File.join(RSpec.configuration.fixture_path, "assets/gb_banner.jpg"))
      @file.original_filename = "gluttonberg_banner.jpg"
      @file.content_type = "image/jpeg"
      @file.size = 300

      @param = {
        :name =>"temp file",
        :file => @file,
        :description =>"<p>test</p>"
      }

      Gluttonberg::Library.bootstrap

      @asset = Asset.new( @param )
      @asset.save

      @locale = Gluttonberg::Locale.generate_default_locale
      @page = Page.create! :name => 'first name', :description_name => 'generic_page'
      
      @page.current_localization.contents = prepare_content_data(@page.current_localization.contents, @asset)
      @page.current_localization.save
      @page.save

      @page = Page.find(@page.id)
    end

    after :all do
      clean_all_data
    end

    it "gb_image_url" do
      helper.gb_image_url(:image).should_not be_nil
      helper.gb_image_url(:image).should eql(@asset.url)
      helper.gb_image_url(:image, :url_for => :fixed_image).should_not be_nil
      helper.gb_image_url(:image, :url_for => :fixed_image).should eql(@asset.url_for(:fixed_image))
    end

    it "gb_image_alt_text" do
      helper.gb_image_alt_text(:image).should_not be_nil
      helper.gb_image_alt_text(:image).should eql("temp file")
    end

    it "enable_slug_management_on(html_class)" do
      helper.enable_slug_management_on("title").should eql("<script type=\"text/javascript\">\n//<![CDATA[\nenable_slug_management_on('title')\n//]]>\n</script>")
    end

    it "enable_redactor(html_class)" do
      script = "<script type=\"text/javascript\">\n//<![CDATA[\nenableRedactor('.text_editor', 0); \n\n//]]>\n</script>"
      helper.enable_redactor("text_editor").should eql(script)
      Setting.update_settings("enable_WYSIWYG" => "No")
      helper.enable_redactor("text_editor").should be_nil
      Setting.update_settings("enable_WYSIWYG" => "Yes")
      helper.enable_redactor("text_editor").should eql(script)
    end

    it "content_editor(content_class)" do
      @page.current_localization.contents.each do |content|
        helper.content_editor(content).should_not be_nil
      end
    end

  end 
end