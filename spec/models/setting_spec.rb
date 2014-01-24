# encoding: utf-8

require 'spec_helper'

module Gluttonberg
  describe Setting do
    before(:all) do
      
    end

    after(:all) do
      clean_all_data
    end

    it "single site settings" do
      Gluttonberg::Setting.count.should == 0
      Rails.configuration.multisite.should == false
      Gluttonberg::Setting.generate_common_settings
      Gluttonberg::Setting.count.should > 0
      Gluttonberg::Setting.all.each do |setting|
        setting.site.should == nil
      end
      Rails.configuration.multisite = {:site1 => "site1.dev:5000", :site2 => "site2.dev:5000" }
      Rails.configuration.multisite.should == {:site1 => "site1.dev:5000", :site2 => "site2.dev:5000" }
      Gluttonberg::Setting.generate_common_settings
      Gluttonberg::Setting.count.should > 0
      Gluttonberg::Setting.where(:site => 'site1').count.should > 0
      Gluttonberg::Setting.where(:site => 'site1').count.should == Gluttonberg::Setting.where(:site => 'site2').count
      
      #after cleanup
      Gluttonberg::Setting.all.each{|setting| setting.destroy}
      Gluttonberg::Setting.generate_common_settings
      Gluttonberg::Setting.count.should > 0
      Gluttonberg::Setting.where(:site => 'site1').count.should > 0
      Gluttonberg::Setting.where(:site => 'site1').count.should == Gluttonberg::Setting.where(:site => 'site2').count
    
      Rails.configuration.multisite = false
      Rails.configuration.multisite.should == false

      Gluttonberg::Setting.all.each{|setting| setting.destroy}
      Gluttonberg::Setting.generate_common_settings
      Gluttonberg::Setting.count.should > 0
      Gluttonberg::Setting.all.each do |setting|
        setting.site.should == nil
      end
    end

  end
end