# encoding: utf-8

require 'spec_helper'

module Gluttonberg
  describe Page do

    before(:all) do
      @locale = Gluttonberg::Locale.generate_default_locale
      @page = Page.create! :name => 'first name', :description_name => 'generic_page'
      Gluttonberg::Setting.generate_common_settings
    end

    after(:all) do
      clean_all_data
    end

    it "should return correct layout name" do
      @page.layout.should == "public"
    end

    it "should have correct title" do
      @page.title.should == "first name"
    end

    it "should have correct nav_label" do
      @page.nav_label.should == "first name"
      page = Page.create! :name => 'first name 2', :description_name => 'generic_page'
      page.current_localization.update_attributes(:navigation_label => "Temporary Page")
      page.nav_label.should == "Temporary Page"
    end

    it "should be able to load localizations" do
      @page.load_localization(Locale.first_default)
    end

    it "should return correct be public page if no group is allocated" do
      @page.is_public?.should == true
    end

    it "should return correct view name" do
      @page.view.should == "generic"
    end

    it "should return correct path" do
      @page.path.should == "first-name"
      localize = Engine.config.localize
      Engine.config.localize = false
      @page.public_path.should == "/first-name"
      Engine.config.localize = true
      @page.public_path.should == "/en-au/first-name"
      Engine.config.localize = localize
    end

    it "should return correct name_and_code" do
      @page.current_localization.name_and_code.should == "first name (Australia English)"
    end

    it "should have only one home page at a time" do
      current_home = Page.create(:name => "Page1" , :home => true , :description_name => 'home')
      page2 = Page.create(:name => "Page2" , :description_name => 'home')
      page2.reload
      current_home.reload

      Page.home_page.id.should == current_home.id
      Page.home_page_name.should == current_home.name

      current_home.home.should be_true
      page2.home.should be_false

      page3 = Page.create(:name => "Page3" , :description_name => 'home')
      page4 = Page.create(:name => "Page4" , :home => true, :description_name => 'home')

      current_home.reload
      page4.reload

      page4.home.should be_true
      current_home.home.should be_false

      page5 = Page.create(:name => "Page5" , :description_name => 'home')
      new_home = Page.create(:name => "New Home", :description_name => 'home')

      new_home.update_attributes(:home => true)

      new_home.reload
      current_home.reload

      new_home.home.should be_true
      current_home.home.should be_false
    end



    it "should load contents (html_contents, image_contents, plain_text_contents)" do
      @page.respond_to?(:html_contents).should == true
      @page.respond_to?(:image_contents).should == true
      @page.respond_to?(:plain_text_contents).should == true

      #in my example newsletter has one content for each type
      @page.html_contents.length.should == 1
      @page.image_contents.length.should == 1
      @page.plain_text_contents.length.should == 1
    end

    it "should have parent and children assoications" do
      p1 = Page.create(:name => "P1" , :description_name => 'home' )
      p2 = Page.create(:name => "P2" , :description_name => 'home' , :parent => p1)
      p1.children.length.should == 1
      p2.parent.id.should == p1.id
    end


    it "should do slug management. If slug is not available it should make slug from title of the page by cleaning it. It should work with ruby 1.9.2" do
      page = Page.new(:name => "Page ”Slug Test" , :description_name => 'home')

      page.slug.blank?.should == true

      page.valid?
      page.slug.blank?.should == false
      page.slug.should == "page-slug-test"

      page.slug = "Page \t Slug ′‟‛„‚”“”˝\(\)\;\:\@\&\=\+\$\,\/?\%\#\[\]] Test"
      page.slug.should == "page-slug-test"
    end

    it "should create versioned content" do
      p = Page.create! :name => '2nd name', :description_name => 'generic_page'
      p.new_record?.should == false
      p.reload
      p.current_localization.localized_contents.each do |loc|
        loc.versions.size.should == 1
        loc.version.should == 1
        loc.class.versioned_class.should == loc.versions.first.class
      end
    end

    it "should be able to save without revision" do
      p = Page.find_by_name('first name')
      p.current_localization.localized_contents.each do |loc|
        loc.save_without_revision
        old_versions = loc.versions.count
        loc.without_revision do
          loc.update_attributes :text => 'changed'
        end
        old_versions.should == loc.versions.count
      end
    end

    it "should rollback with version number" do
      p = Page.find_by_name('first name')

      p.current_localization.localized_contents.each do |loc|
        loc.version.should == 1

        loc.text = "first name v2"
        loc.save

        loc.version.should == 2
        loc.text.should == 'first name v2'

        loc.revert_to!(1)
        loc.version.should == 1
        loc.text.should be_nil
        loc.versions.size.should == 2

        loc.revert_to!(2)
        loc.version.should == 2
        loc.text.should == 'first name v2'
        loc.versions.size.should == 2
      end
    end

    it "should not cross version limit" do
      p = Page.find_by_name('first name')

      p.current_localization.localized_contents.each do |loc|
        loc.version.should == 1

        (2..10).each do |i|
          loc.update_attributes :text => "first name v#{i}"
          loc.version.should == i
          loc.text.should == "first name v#{i}"
          loc.versions.size.should == i
        end

        loc.update_attributes :text => "first name v11"
        loc.version.should == 11
        loc.text.should == 'first name v11'
        loc.versions.size.should == 10
      end
    end

    it "redirect_required? && redirect_url" do
      page = Page.create! :name => 'redirect required', :description_name => 'redirect_to_remote'
      page.redirect_required?.should == true
      page.path.should == "redirect-required"
      page.redirect_url.should == "http://www.freerangefuture.com"
      @page.redirect_required?.should == false

      page = Page.create! :name => 'redirect to path', :description_name => 'redirect_to_path'
      page.redirect_required?.should == true
      page.redirect_url.should == "/local-path"
    end 

    it "rewrite_required?" do
      page = Page.create! :name => 'rewrite required', :description_name => 'examples'
      page.rewrite_required?.should == true
      @page.rewrite_required?.should == false
    end 

  end #Page
end