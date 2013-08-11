require 'spec_helper'

module Gluttonberg
  describe Content::ImportExportCSV do

    before :all do
      @locale = Gluttonberg::Locale.generate_default_locale
    end

    after :all do
      clean_all_data
    end

    it "should set class attributes localized" do
      StaffProfile.import_export_columns.should == ["name"]
      StaffProfile.wysiwyg_columns.should == ["bio"]
    end

    it "should export data" do
      prepare_export_data

      csvData = StaffProfile.exportCSV(StaffProfile.all)

      csvData = csvData.split("\n")
      csvData.length.should == 4 #3 data + 1 header rows
      
      firstRow = csvData[0].split(",")
      firstRow.length.should == 4 #4 columns
      firstRow[0].should == "name"
      firstRow[1].should == "bio"
      firstRow[2].should == "published_at"
      firstRow[3].should == "updated_at"

      firstDataRow = csvData[1].split(",")
      firstDataRow.length.should == 4 #4 columns
      firstDataRow[0].should == "Abdul"

      StaffProfile.all.each{|staff| staff.destroy}
    end


    it "should export data with local options" do
      prepare_export_data

      csvData = StaffProfile.exportCSV(StaffProfile.all, {
        :export_columns => [:name, :face_id, :handwritting_id], 
        :wysiwyg_columns => [:bio]
      })

      csvData = csvData.split("\n")
      csvData.length.should == 4 #3 data + 1 header rows
      
      firstRow = csvData[0].split(",")
      firstRow.length.should == 6 #6 columns
      firstRow[0].should == "name"
      firstRow[1].should == "face_id"
      firstRow[2].should == "handwritting_id"
      firstRow[3].should == "bio"
      firstRow[4].should == "published_at"
      firstRow[5].should == "updated_at"

      firstDataRow = csvData[1].split(",")
      firstDataRow.length.should == 6 #6 columns
      firstDataRow[0].should == "Abdul"


      StaffProfile.all.each{|staff| staff.destroy}
    end

    

    it "should import data" do
      StaffProfile.count.should == 0
      file = GbFile.new(File.join(RSpec.configuration.fixture_path, "staff_profiles.csv"))
      file.original_filename = "staff_profiles.csv"

      StaffProfile.importCSV(file)

      StaffProfile.count.should == 3
      staff_profiles = StaffProfile.all
      
      staff_profiles[0].name.should == "Abdul"
      staff_profiles[0].bio.should == "<p>Abdul Rauf is a web and mobile programmer.</p>"
      staff_profiles[0].face_id.should == nil
      staff_profiles[0].handwritting_id.should == nil

      staff_profiles[1].name.should == "David"
      staff_profiles[1].bio.should == "<p>David Walker</p>"
      staff_profiles[1].face_id.should == nil
      staff_profiles[1].handwritting_id.should ==  nil

      staff_profiles[2].name.should == "Nick"
      staff_profiles[2].bio.should == "<p>Nick Crowther</p>"
      staff_profiles[2].face_id.should == nil
      staff_profiles[2].handwritting_id.should == nil


      StaffProfile.all.each{|staff| staff.destroy}
    end

    it "should import data" do
      StaffProfile.count.should == 0

      attrs = {
        :name => "Nick",
        :face_id => 5,
        :bio => "Managing Director",
        :handwritting_id => 9
      }
      staff = StaffProfile.new_with_localization(attrs)
      staff.save

      StaffProfile.count.should == 1

      file = GbFile.new(File.join(RSpec.configuration.fixture_path, "staff_profiles.csv"))
      file.original_filename = "staff_profiles.csv"

      StaffProfile.importCSV(file, {
        :import_columns => [:name, :face_id, :handwritting_id], 
        :wysiwyg_columns => [:bio],
        :unique_key => :name
      })

      StaffProfile.count.should == 3
      staff_profiles = StaffProfile.all
      
      staff_profiles[0].name.should == "Nick"
      staff_profiles[0].bio.should == "<p>Nick Crowther</p>"
      staff_profiles[0].face_id.should == 5
      staff_profiles[0].handwritting_id.should == 9

      staff_profiles[1].name.should == "Abdul"
      staff_profiles[1].bio.should == "<p>Abdul Rauf is a web and mobile programmer.</p>"
      staff_profiles[1].face_id.should == 5
      staff_profiles[1].handwritting_id.should == 9

      staff_profiles[2].name.should == "David"
      staff_profiles[2].bio.should == "<p>David Walker</p>"
      staff_profiles[2].face_id.should == 5
      staff_profiles[2].handwritting_id.should == 9

      


      StaffProfile.all.each{|staff| staff.destroy}
    end


    def prepare_export_data
      StaffProfile.all.each{|staff| staff.destroy}
      StaffProfile.count.should == 0

      attrs = {
        :name => "Abdul",
        :face_id => 5,
        :bio => "Abdul Rauf is a web and mobile programmer.",
        :handwritting_id => 9
      }
      staff = StaffProfile.new_with_localization(attrs)
      staff.save
      staff.publish!

      attrs[:name] = "David"
      attrs[:bio] = "David Walker"
      staff2 = StaffProfile.new_with_localization(attrs)
      staff2.save

      attrs[:name] = "Nick"
      attrs[:bio] = "Nick Crowther"
      staff3 = StaffProfile.new_with_localization(attrs)
      staff3.save

      StaffProfile.count.should == 3
    end

  end
end