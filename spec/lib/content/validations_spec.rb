require 'spec_helper'

module Gluttonberg
  describe Content::Validations do

    before :all do
      @locale = Gluttonberg::Locale.generate_default_locale
    end

    after :all do
      clean_all_data
    end

    it "should validate all string fields in both main and localized models" do
      staff = StaffProfile.new_with_localization({
        :name => "Abdul",
        :face_id => 5,
        :bio => "Abdul Rauf is a web and mobile programmer.",
        :handwritting_id => 9
      })
      staff.valid?.should eql(true)
      staff.name = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin condimentum dui eget felis ullamcorper ornare. Nullam lobortis cursus massa. Duis ut commodo justo. Nam consequat, massa non rhoncus fermentum, neque velit ullamcorper massa, non tincidunt sapien lacus et ni"
      staff.valid?.should eql(false)
      #255 characters
      staff.name = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin condimentum dui eget felis ullamcorper ornare. Nullam lobortis cursus massa. Duis ut commodo justo. Nam consequat, massa non rhoncus fermentum, neque velit ullamcorper massa, non tincidunt sap"
      staff.valid?.should eql(true)

      staff.current_localization.seo_title = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin condimentum dui eget felis ullamcorper ornare. Nullam lobortis cursus massa. Duis ut commodo justo. Nam consequat, massa non rhoncus fermentum, neque velit ullamcorper massa, non tincidunt sapien lacus et ni"
      staff.current_localization.valid?.should eql(false)
      staff.valid?.should eql(false)
    end

    it "should validate all integer fields in both main and localized models" do
      staff = StaffProfile.new_with_localization({
        :name => "Abdul",
        :face_id => 5,
        :bio => "Abdul Rauf is a web and mobile programmer.",
        :handwritting_id => 9
      })
      staff.valid?.should eql(true)
      staff.face_id = "adf"
      staff.valid?.should eql(false)
      staff.face_id = "343"
      staff.valid?.should eql(true)
      staff.face_id = "-343"
      staff.valid?.should eql(true)
      staff.face_id = "+343"
      staff.valid?.should eql(true)
      staff.face_id = "=343"
      staff.valid?.should eql(false)

      staff.current_localization.handwritting_id = "adfa"
      staff.current_localization.valid?.should eql(false)
      staff.valid?.should eql(false)
    end

    it "should validate all decimal fields" do
      staff = StaffProfile.new_with_localization({
        :name => "Abdul",
        :face_id => 5,
        :bio => "Abdul Rauf is a web and mobile programmer.",
        :handwritting_id => 9
      })
      staff.valid?.should eql(true)
      staff.package = "adf"
      staff.valid?.should eql(false)
      staff.package = "343"
      staff.valid?.should eql(true)
      staff.package = "343.34"
      staff.valid?.should eql(true)
      staff.package = "123456.3"
      staff.valid?.should eql(true)
      staff.package = "123456.33"
      staff.valid?.should eql(true)
      staff.package = "123456.333"
      staff.valid?.should eql(true)
      staff.package = "1234567.3"
      staff.valid?.should eql(false)
      staff.package = "123456.3444"
      staff.valid?.should eql(false)
      
      staff.package = "-123456.3"
      staff.valid?.should eql(true)
      staff.package = "+123456.3"
      staff.valid?.should eql(true)
    end
  end
end