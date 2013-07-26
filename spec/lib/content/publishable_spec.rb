require 'spec_helper'

module Gluttonberg
  describe Content::Publishable do

    before :all do
      @locale = Gluttonberg::Locale.generate_default_locale
    end

    after :all do
      clean_all_data
    end

    it "should be able to publish, unpublish and archive" do
      page = Page.create! :name => 'first name', :description_name => 'generic_page'

      page.published?.should == false
      page.publish!
      page.published?.should == true
      Page.where(:id => page.id).first.published?.should == true
      page.publishing_status.should == "Published"

      page.unpublish!
      page.published?.should == false
      Page.where(:id => page.id).first.published?.should == false
      page.publishing_status.should == "Draft"

      page.publish!
      page.published?.should == true
      Page.where(:id => page.id).first.published?.should == true

      page.unpublish
      page.published?.should == false
      Page.where(:id => page.id).first.published?.should == true
      page.unpublish!

      page.publish
      page.published?.should == true
      Page.where(:id => page.id).first.published?.should == false
      page.publish!

      page.archive!
      page.archived?.should == true
      Page.where(:id => page.id).first.archived?.should == true
      page.publish!

      page.archive
      page.archived?.should == true
      Page.where(:id => page.id).first.archived?.should == false
      page.publishing_status.should == "Archived"

    end
  end
end