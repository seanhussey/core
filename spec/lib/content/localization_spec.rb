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
      StaffProfile.localized_fields.should == [
        "id",
        "bio", "handwritting_id",
        "seo_title", 
        "seo_keywords",
        "seo_description",
        "fb_icon_id",
        "parent_id",
        "locale_id",
        "created_at",
        "updated_at"
      ]
    end

    it "instance should be localized" do
      staff = StaffProfile.new_with_localization
      staff.localized?.should == true
    end

    it "new_with_localization should set attributes to right model" do
      staff = StaffProfile.new_with_localization({
        :name => "Abdul",
        :face_id => 5,
        :bio => "Abdul Rauf is a web and mobile programmer.",
        :handwritting_id => 9
      })
      staff.localized?.should == true
      staff.name.should == "Abdul"
      staff.face_id.should == 5
      staff.bio.should == "Abdul Rauf is a web and mobile programmer."
      staff.handwritting_id.should == 9

      staff.current_localization.bio.should == "Abdul Rauf is a web and mobile programmer."
      staff.current_localization.handwritting_id.should == 9
    end

    it "on save it should save all attributes" do
      staff = StaffProfile.new_with_localization({
        :name => "Abdul",
        :face_id => 5,
        :bio => "Abdul Rauf is a web and mobile programmer.",
        :handwritting_id => 9
      })
      staff.save

      staff = StaffProfile.find(staff.id)
      staff.localized?.should == true
      staff.name.should == "Abdul"
      staff.face_id.should == 5
      staff.bio.should == "Abdul Rauf is a web and mobile programmer."
      staff.handwritting_id.should == 9

      staff.current_localization.bio.should == "Abdul Rauf is a web and mobile programmer."
      staff.current_localization.handwritting_id.should == 9

      staff = StaffProfile.find(staff.id)
      staff.load_localization(Gluttonberg::Locale.first_default)
      staff.current_localization.handwritting_id.should == 9

      staff.destroy
    end

    it "should create missing localization" do
      staff = StaffProfile.new({
        :name => "Abdul",
        :face_id => 5
      })
      staff.localized?.should == true
      staff.name.should == "Abdul"
      staff.face_id.should == 5
      
      staff.save
      staff = StaffProfile.find(staff.id)
      staff.load_localization(Gluttonberg::Locale.first_default)

      staff.current_localization.bio.should == nil
      staff.current_localization.handwritting_id.should == nil

      staff.destroy
    end


  end
end