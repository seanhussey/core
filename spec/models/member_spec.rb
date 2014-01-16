require 'spec_helper'

module Gluttonberg
  describe Member do
    before :all do
      @params = {
        :first_name => "First",
        :email => "valid_user@test.com",
        :password => "password1",
        :password_confirmation => "password1"
      }
    end

    after :all do
      clean_all_data
    end

    it "should generate valid random password" do

    end

    it "should validate password ((must be a minimum of 6 characters in length, contain at least 1 letter and at least 1 number))" do
      valid_member = Member.new(@params)
      valid_member.valid?.should == true

      invalid_member = Member.new(@params.merge({:password => "password", :password_confirmation => "password"}))
      invalid_member.valid?.should == false

      invalid_member = Member.new(@params.merge({:password => "pass1", :password_confirmation => "pass1"}))
      invalid_member.valid?.should == false

      invalid_member = Member.new(@params.merge({:password => "~!#-^&*()", :password_confirmation => "~!#-^&*()"}))
      invalid_member.valid?.should == false

      invalid_member = Member.new(@params.merge({:password => "pas1#", :password_confirmation => "pas1#"}))
      invalid_member.valid?.should == false

      valid_member = Member.new(@params.merge({:password => "pass1!@#", :password_confirmation => "pass1!@#"}))
      valid_member.valid?.should == true
    end

    it "should assign groups" do
      sales_group = Group.create(:name => "Sales")
      production_group = Group.create(:name => "Production")
      staff_group = Group.create(:name => "Staff", :default => true)

      valid_member = Member.new(@params)
      valid_member.groups = [sales_group, production_group]

      valid_member.groups.should == [sales_group, production_group]
      valid_member.save
      valid_member.groups.should == [sales_group, production_group]

      valid_member.groups_name.should == "Sales, Production"

      valid_member.have_group?([sales_group, production_group]).should == true
      valid_member.have_group?([sales_group]).should == true
      valid_member.have_group?([production_group]).should == true
      valid_member.have_group?([sales_group, production_group, staff_group]).should == true

      sales_group.destroy
      production_group.destroy
      staff_group.destroy
      valid_member.destroy
    end


    it "should correctly find page access for a member" do
      sales_group = Group.create(:name => "Sales")
      production_group = Group.create(:name => "Production")
      staff_group = Group.create(:name => "Staff", :default => true)

      valid_member = Member.new(@params)
      valid_member.groups = [sales_group, production_group]
      valid_member.save

      @page1 = Page.new :name => 'first name', :description_name => 'generic_page'
      @page1.groups = [sales_group, staff_group]
      @page1.save

      @page2 = Page.new :name => 'first name', :description_name => 'generic_page'
      @page2.groups = [sales_group, production_group]
      @page2.save

      @page3 = Page.new :name => 'first name', :description_name => 'generic_page'
      @page3.groups = [production_group]
      @page3.save

      @page4 = Page.new :name => 'first name', :description_name => 'generic_page'
      @page4.groups = [staff_group]
      @page4.save

      @page5 = Page.new :name => 'first name', :description_name => 'generic_page'
      @page5.groups = []
      @page5.save

      @page6 = Page.new :name => 'first name', :description_name => 'generic_page'
      @page6.save

      valid_member.does_member_have_access_to_the_page?(@page1).should == true
      valid_member.does_member_have_access_to_the_page?(@page2).should == true
      valid_member.does_member_have_access_to_the_page?(@page3).should == true
      valid_member.does_member_have_access_to_the_page?(@page4).should == false
      valid_member.does_member_have_access_to_the_page?(@page5).should == false
      valid_member.does_member_have_access_to_the_page?(@page6).should == false

      #delete groups
      sales_group.destroy
      production_group.destroy
      staff_group.destroy

      valid_member.destroy

      @page1.destroy
      @page2.destroy
      @page3.destroy
      @page4.destroy
      @page5.destroy

    end

    it "extend model" do
      valid_member = Member.new(@params)
      valid_member.my_name.should == "First - "
    end

  end
end