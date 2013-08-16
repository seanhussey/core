require 'spec_helper'

module Gluttonberg
  describe Membership::Export do

    before :all do
      @locale = Gluttonberg::Locale.generate_default_locale
    end

    after :all do
      clean_all_data
    end


    it "should export data" do
      Gluttonberg::Member.all{|staff| staff.destroy}
      prepare_export_data

      csvData = Member.exportCSV
      all_records = Member.order("id asc").all

      csvData = csvData.split("\n")
      csvData.length.should == 4 #3 data + 1 header rows
      
      firstRow = csvData[0].split(",")
      firstRow.length.should == 6 #6 columns
      csvData[0].should == "DATABASE ID,FIRST NAME,LAST NAME,EMAIL,GROUPS,BIO"

      firstDataRow = csvData[1].split(",")
      firstDataRow.length.should == 6 #4 columns
      firstDataRow[1].should == all_records.first.first_name
      firstDataRow[2].should == all_records.first.last_name
      firstDataRow[3].should == all_records.first.email
      firstDataRow[4].should == "\"#{all_records.first.groups_name}\""
      firstDataRow[5].should == "#{all_records.first.bio}"

      Gluttonberg::Member.all{|staff| staff.destroy}
    end


    def prepare_export_data
      Member.all{|staff| staff.destroy}
      Member.count.should == 0

      # generate random password
      temp_password = Gluttonberg::Member.generateRandomString
      
      attrs = {
        :first_name => "Abdul",
        :last_name => "Rauf",
        :email => "test@test.com",
        :bio => "Abdul Rauf is a web and mobile programmer.",
        :password => temp_password ,
        :password_confirmation => temp_password
      }
      staff = Member.new(attrs)
      staff.save.should == true

      # generate random password
      temp_password = Gluttonberg::Member.generateRandomString
      attrs = {
        :first_name => "David",
        :last_name => "Walker",
        :email => "test2@test.com",
        :bio => "David Walker",
        :password => temp_password ,
        :password_confirmation => temp_password
      }
      staff2 = Member.new(attrs)
      staff2.save.should == true

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
      staff3 = Gluttonberg::Member.new(attrs)
      staff3.save.should == true

      Gluttonberg::Member.count.should == 3
    end

  end
end