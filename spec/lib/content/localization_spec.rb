require 'spec_helper'

module Gluttonberg
  describe Content::Localization do

    before :all do
      @locale = Gluttonberg::Locale.generate_default_locale
    end

    after :all do
      clean_all_data
    end

    it "should be localized" do
      StaffProfile.localized?.should == true
    end

    it "should have localized class"  do
      StaffProfile.localized_model.name.should == "StaffProfileLocalization"
      StaffProfile.localized_model_name.should == "StaffProfileLocalization"
    end

    it "should have correct localized fields"  do
      #StaffProfile.localized_fields.should == [:bio, :handwritting_id]
    end



  end
end