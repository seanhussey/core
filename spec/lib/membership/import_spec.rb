require 'spec_helper'

module Gluttonberg
  describe Membership::Import do

    before :all do
      @locale = Gluttonberg::Locale.generate_default_locale
    end

    after :all do
      clean_all_data
    end

    it "should raise error for invalid csv file" do
      successfull , failed , updated = Member.importCSV(File.join(RSpec.configuration.fixture_path, "wrong file.csv"), false ,nil)
      successfull.should == "Please provide a valid CSV file with correct column names."
    end

    it "should import members" do
      # generate random password
      temp_password = Gluttonberg::Member.generateRandomString
      attrs = {
        :first_name => "Nick",
        :last_name => "Crowther",
        :email => "test1@test.com",
        :bio => "Nick Crowther",
        :password => temp_password,
        :password_confirmation => temp_password
      }
      staff3 = Member.new(attrs)
      staff3.save

      developer = Group.create(:name => "Developer")
      admin = Group.create(:name => "Admin")
      staff = Group.create(:name => "Staff", :default => true)
      Member.count.should == 1
      successfull , failed , updated = Member.importCSV(File.join(RSpec.configuration.fixture_path, "members.csv"), false ,staff.id)

      Member.count.should == 3
      staff_profiles = Member.order("id ASC").all

      successfull.length.should == 2
      failed.length.should == 1
      updated.length.should == 1
      
      staff_profiles[0].first_name.should == "Nick"
      staff_profiles[0].last_name.should == "Crowther"
      staff_profiles[0].bio.should == ""
      staff_profiles[0].groups_name.should == "Staff"
      staff_profiles[0].email.should == "test1@test.com"

      staff_profiles[1].first_name.should == "Abdul"
      staff_profiles[1].last_name.should == "Rauf"
      staff_profiles[1].bio.should == "Abdul Rauf is a web and mobile programmer."
      staff_profiles[1].groups_name.should == "Developer, Staff"
      staff_profiles[1].email.should == "test@test.com"

      staff_profiles[2].first_name.should == "David"
      staff_profiles[2].last_name.should == "Walker"
      staff_profiles[2].bio.should == nil
      staff_profiles[2].groups_name.should == "Developer, Admin, Staff"
      staff_profiles[2].email.should == "test2@test.com"

      Member.all{|staff| staff.destroy}
    end

  end
end