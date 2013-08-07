require 'spec_helper'

module Gluttonberg
  describe Content::ImportExportCSV do

    before :all do
      @locale = Gluttonberg::Locale.generate_default_locale
    end

    after :all do
      clean_all_data
      StaffProfile.all{|staff| staff.destroy}
    end

    it "should set class attributes localized" do
      StaffProfile.import_export_columns.should == ["name"]
      StaffProfile.wysiwyg_columns.should == ["bio"]
    end

    it "should import data" do
      #.importCSV(params[:csv].tempfile.path)
    end

    it "should export data" do
      

      StaffProfile.all{|staff| staff.destroy}
    end


  end
end