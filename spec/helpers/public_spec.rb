# encoding: utf-8

require 'spec_helper'

module Gluttonberg
  describe Public do
    before :all do
      Gluttonberg::Setting.generate_common_settings
    end

    after :all do
      clean_all_data
    end

    it "current_localization_slug" do
      locale = Gluttonberg::Locale.generate_default_locale
      helper.current_localization_slug.should eql("en")
      assign(:locale, locale)
      helper.current_localization_slug.should eql("en")
    end

    it "google_analytics_js_tag" do
      helper.google_analytics_js_tag.should be_nil
      Setting.update_settings("google_analytics" => "UA-xxxxxxx")
      helper.google_analytics_js_tag.should eql("<script type=\"text/javascript\">\n//<![CDATA[\n\n              var _gaq = _gaq || [];\n              _gaq.push(['_setAccount', 'UA-xxxxxxx']);\n              _gaq.push(['_trackPageview']);\n              (function() {\n                var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;\n                ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';\n                var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);\n              })();\n            \n//]]>\n</script>")
      Setting.update_settings("google_analytics" => nil)
      helper.google_analytics_js_tag.should be_nil
    end

    it "clean_public_query" do
      helper.clean_public_query(nil).should be_nil
      helper.clean_public_query("").should eql("")
      helper.clean_public_query(" ").should eql(" ")
      helper.clean_public_query("test").should eql("test")
      helper.clean_public_query("test data").should eql("test data")
      helper.clean_public_query("test 'data'").should eql("test \\'data\\'")
      helper.clean_public_query("test \"data\"").should eql("test \\\"data\\\"")
      helper.clean_public_query("test $ data").should eql("test $ data")
      helper.clean_public_query("test $$ data").should eql("test $ data")
      helper.clean_public_query("$$$test $$$ data").should eql("$test $ data")
    end

    it "clean_public_query_for_sphinx" do
      helper.clean_public_query_for_sphinx(nil).should be_nil
      helper.clean_public_query_for_sphinx("").should eql("")
      helper.clean_public_query_for_sphinx(" ").should eql(" ")
      helper.clean_public_query_for_sphinx("test").should eql("test")
      helper.clean_public_query_for_sphinx("test data").should eql("test data")
      helper.clean_public_query_for_sphinx("test 'data'").should eql("test data")
      helper.clean_public_query_for_sphinx("test \"data\"").should eql("test data")
      helper.clean_public_query_for_sphinx("test $ data").should eql("test  data")
      helper.clean_public_query_for_sphinx("test $$ data").should eql("test  data")
      helper.clean_public_query_for_sphinx("$$$test $$$ data").should eql("test  data")

      helper.clean_public_query_for_sphinx("test '\"″′‟‘’‛„‚”“”˝ ").should eql("test  ")
    end

    it "cms_based_public_css" do
      Rails.configuration.cms_based_public_css.should eql(false)

      helper.cms_managed_stylesheets_link_tag.should be_nil

      @stylesheet = Stylesheet.create({
        :name => "style",
        :value => "p{ font-size: 10px; }"
      })

      @stylesheet1 = Stylesheet.create({
        :name => "player",
        :value => "a{ font-size: 11px; }"
      })

      helper.cms_managed_stylesheets_link_tag.should be_nil

      Rails.configuration.cms_based_public_css = true
      Rails.configuration.cms_based_public_css.should eql(true)

      helper.cms_managed_stylesheets_link_tag.should eql("<link href=\"/stylesheets/style.css?1.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" /><link href=\"/stylesheets/player.css?1.css\" media=\"screen\" rel=\"stylesheet\" type=\"text/css\" />\n")

      Rails.configuration.cms_based_public_css = false
      Rails.configuration.cms_based_public_css.should eql(false)

    end

    it "shortcode_safe" do
      shortcode_safe("test").should == "test"
      shortcode_safe("test [test_shortcode] sentence").should == "test [test_shortcode] sentence"
      
      Gluttonberg::Embed.create(:title => "Test", :shortcode => "test_shortcode", :body => "<p>test</p>")

      shortcode_safe("test [test_shortcode] sentence").should == "test <p>test</p> sentence"
      shortcode_safe("test[test_shortcode]sentence").should == "test<p>test</p>sentence"
      shortcode_safe("[gallery test]").should == "[gallery test]"

      gallery = Gluttonberg::Gallery.new(:title => "test")
      gallery.user_id = 1
      gallery.save
      asset  = create_image_asset

      def gallery_shortcode(args)
        if args.length == 1
          gallery_ul(args.first, :jwysiwyg_image, :fixed_image, {:class => "gallery-ul-class"}, {:class => "gallery-li-class"}, {:class => "gallery-a-class"})
        end
      end

      shortcode_safe("[gallery test]").should == ""
      gallery.gallery_images.create(:asset_id => asset.id)
      shortcode_safe("[gallery test]").should == ""
      gallery.publish!
      shortcode_safe("[gallery test]").should == gallery_ul(gallery.slug, :jwysiwyg_image, :fixed_image, {:class => "gallery-ul-class"}, {:class => "gallery-li-class"}, {:class => "gallery-a-class"}).html_safe
    end
    
  end #public helpers
end