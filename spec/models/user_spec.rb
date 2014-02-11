require 'spec_helper'

describe User do
  before :all do
    @all_roles = ["super_admin" , "admin", 'editor' , "contributor", "sales", "accounts"]
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

  it "should not allow mass assignment for role" do
    begin
      User.new(@params.merge({:role => "super_admin"}) )
    rescue => e
      e.class.should == ActiveModel::MassAssignmentSecurity::Error
    end
  end

  it "should validate password format (must be a minimum of 6 characters in length, contain at least 1 letter and at least 1 number)" do
    valid_user = User.new(@params)
    valid_user.role = "super_admin"

    valid_user.valid?.should == true


    invalid_user = User.new(@params.merge({:password => "password", :password_confirmation => "password"}))
    invalid_user.role = "super_admin"
    invalid_user.valid?.should == false

    invalid_user = User.new(@params.merge({:password => "pass1", :password_confirmation => "pass1"}))
    invalid_user.role = "super_admin"
    invalid_user.valid?.should == false

    invalid_user = User.new(@params.merge({:password => "~!#-^&*()", :password_confirmation => "~!#-^&*()"}))
    invalid_user.role = "super_admin"
    invalid_user.valid?.should == false

    invalid_user = User.new(@params.merge({:password => "pas1#", :password_confirmation => "pas1#"}))
    invalid_user.role = "super_admin"
    invalid_user.valid?.should == false

    valid_user = User.new(@params.merge({:password => "pass1!@#", :password_confirmation => "pass1!@#"}))
    valid_user.role = "super_admin"
    valid_user.valid?.should == true
  end


  it "should validate presense of first_name" do
    valid_user = User.new(@params)
    valid_user.role = "super_admin"

    valid_user.first_name = nil
    valid_user.valid?.should == false
  end

  it "should validate presense of email" do
    valid_user = User.new(@params)
    valid_user.role = "super_admin"
    valid_user.email = nil
    valid_user.valid?.should == false
  end

  it "should validate presense of role" do
    valid_user = User.new(@params)
    valid_user.role = "super_admin"

    valid_user.role = nil
    valid_user.valid?.should == false
  end

  it "user_valid_roles should return correct roles list " do
    current_user = User.new(@params.merge(:email =>"current_user@test.com"))
    current_user.role = "super_admin"
    current_user.save

    user = User.new(@params.merge(:email =>"current_user@test.com"))
    user.role = "super_admin"
    user.save

    current_user.role = "super_admin"
    current_user.user_valid_roles(user).should == @all_roles
    current_user.user_valid_roles(current_user).should == []

    current_user.role = "admin"
    current_user.user_valid_roles(user).should == ["admin", 'editor', "contributor", "sales", "accounts"]
    current_user.user_valid_roles(current_user).should == []

    current_user.role = "contributor"
    current_user.user_valid_roles(user).should == ["contributor"]
    current_user.user_valid_roles(current_user).should == []

    current_user.destroy
    user.destroy
  end


  it "should ask for password_confirmation if password is present" do
     params = {
      :first_name => "First",
      :email => "test1@test.com",
      :password => "password1"
    }
    user = User.new(params)
    user.role = "super_admin"
    user.valid?.should == false
  end

  it "should be able to add new user roles" do
    User.user_roles.should == @all_roles
  end

  it "should correctly search users based on current_user role" do
    params = {
      :first_name => "First",
      :email => "user1@test.com",
      :password => "password1",
      :password_confirmation => "password1"
    }
    user1 = User.new(params)
    user1.role = "super_admin"
    user1.save

    user2 = User.new(params.merge(:email => "user2@test.com"))
    user2.role = "super_admin"
    user2.save

    user3 = User.new(params.merge(:email => "user3@test.com"))
    user3.role = "admin"
    user3.save

    user4 = User.new(params.merge(:email => "user4@test.com"))
    user4.role = "admin"
    user4.save

    user5 = User.new(params.merge(:email => "user5@test.com"))
    user5.role = "contributor"
    user5.save

    user6 = User.new(params.merge(:email => "user6@test.com"))
    user6.role = "contributor"
    user6.save

    user7 = User.new(params.merge(:email => "user7@test.com"))
    user7.role = "sales"
    user7.save

    user8 = User.new(params.merge(:email => "user8@test.com"))
    user8.role = "sales"
    user8.save

    #super admin searching
    User.search_users("First", user1, "updated_at DESC").length.should == 8
    User.search_users("user1", user1, "updated_at DESC").length.should == 1
    User.search_users("user2", user1, "updated_at DESC").length.should == 1

    #admin searching
    User.search_users("First", user3, "updated_at DESC").length.should == 6
    User.search_users("user2", user3, "updated_at DESC").length.should == 0
    User.search_users("user3", user3, "updated_at DESC").length.should == 1
    User.search_users("user4", user3, "updated_at DESC").length.should == 1

    #contributor searching
    User.search_users("First", user5, "updated_at DESC").length.should == 1
    User.search_users("user2", user5, "updated_at DESC").length.should == 0
    User.search_users("user3", user5, "updated_at DESC").length.should == 0
    User.search_users("user5", user5, "updated_at DESC").length.should == 1
    User.search_users("user6", user5, "updated_at DESC").length.should == 0

    #sales searching
    User.search_users("First", user7, "updated_at DESC").length.should == 1
    User.search_users("user2", user7, "updated_at DESC").length.should == 0
    User.search_users("user3", user7, "updated_at DESC").length.should == 0
    User.search_users("user7", user7, "updated_at DESC").length.should == 1
    User.search_users("user8", user7, "updated_at DESC").length.should == 0

    user1.destroy
    user2.destroy
    user3.destroy
    user4.destroy
    user5.destroy
    user6.destroy
    user7.destroy
    user8.destroy
  end

  it "should correctly find user based on current_user role" do
    params = {
      :first_name => "First",
      :email => "user1@test.com",
      :password => "password1",
      :password_confirmation => "password1"
    }
    user1 = User.new(params)
    user1.role = "super_admin"
    user1.save

    user2 = User.new(params.merge(:email => "user2@test.com"))
    user2.role = "super_admin"
    user2.save

    user3 = User.new(params.merge(:email => "user3@test.com"))
    user3.role = "admin"
    user3.save

    user4 = User.new(params.merge(:email => "user4@test.com"))
    user4.role = "admin"
    user4.save

    user5 = User.new(params.merge(:email => "user5@test.com"))
    user5.role = "contributor"
    user5.save

    user6 = User.new(params.merge(:email => "user6@test.com"))
    user6.role = "contributor"
    user6.save

    user7 = User.new(params.merge(:email => "user7@test.com"))
    user7.role = "sales"
    user7.save

    user8 = User.new(params.merge(:email => "user8@test.com"))
    user8.role = "sales"
    user8.save

    #super admin searching
    User.find_user(user1.id, user1).blank?.should == false
    User.find_user(user2.id, user1).blank?.should == false
    User.find_user(user3.id, user1).blank?.should == false
    User.find_user(user5.id, user1).blank?.should == false
    User.find_user(user7.id, user1).blank?.should == false

    #admin searching
    User.find_user(user1.id, user3).blank?.should == true
    User.find_user(user3.id, user3).blank?.should == false
    User.find_user(user4.id, user3).blank?.should == false
    User.find_user(user5.id, user3).blank?.should == false
    User.find_user(user7.id, user3).blank?.should == false

    #contributor searching
    User.find_user(user1.id, user5).blank?.should == true
    User.find_user(user3.id, user5).blank?.should == true
    User.find_user(user5.id, user5).blank?.should == false
    User.find_user(user6.id, user5).blank?.should == true
    User.find_user(user7.id, user5).blank?.should == true

    #sales searching
    User.find_user(user1.id, user7).blank?.should == true
    User.find_user(user3.id, user7).blank?.should == true
    User.find_user(user5.id, user7).blank?.should == true
    User.find_user(user7.id, user7).blank?.should == false
    User.find_user(user8.id, user7).blank?.should == true

    user1.destroy
    user2.destroy
    user3.destroy
    user4.destroy
    user5.destroy
    user6.destroy
    user7.destroy
    user8.destroy
  end


  it "should authorize contributor for model and object access" do
    @page = Gluttonberg::Page.create! :name => 'first name', :description_name => 'generic_page'
    @page1 = Gluttonberg::Page.create! :name => 'first name', :description_name => 'generic_page', :parent_id => @page.id
    @page2 = Gluttonberg::Page.create! :name => 'first name', :description_name => 'generic_page', :parent_id => @page1.id
    @staff1 = StaffProfile.create! :name => "Abdul"
    @staff2 = StaffProfile.create! :name => "Abdul"
    @staff3 = StaffProfile.create! :name => "Abdul"
    asset1 = create_image_asset
    asset2 = create_image_asset

    params = {
      :first_name => "First",
      :email => "super_admin@test.com",
      :password => "password1",
      :password_confirmation => "password1"
    }
    super_admin = User.new(params)
    super_admin.role = "super_admin"
    super_admin.save

    admin = User.new(params.merge(:email => "admin@test.com"))
    admin.role = "admin"
    admin.save

    editor = User.new(params.merge(:email => "editor@test.com"))
    editor.role = "editor"
    editor.save

    contributor = User.new(params.merge(:email => "contributor@test.com"))
    contributor.role = "contributor"
    contributor.save

    @staff1.user_id = contributor.id
    @staff1.save
    @staff2.user_id = contributor.id
    @staff2.save
    @staff3.user_id = editor.id
    @staff3.save

    @staff2.publish!

    asset1.user_id = contributor.id
    asset1.save
    asset2.user_id = editor.id
    asset2.save

    #super admin authorization
    super_admin.ability.can?(:manage_object, @page).should == true
    super_admin.ability.can?(:manage_model, "StaffProfile").should == true

    #admin authorization
    admin.ability.can?(:manage_object, @page).should == true
    admin.ability.can?(:manage_model, "StaffProfile").should == true


    #editor authorization
    editor.ability.can?(:manage_object, @page).should == true
    editor.ability.can?(:manage_object, @page).should == true
    editor.ability.can?(:manage_object, @page1).should == true
    editor.ability.can?(:manage_object, @page2).should == true
    editor.can_view_page(@page).should == true
    editor.can_view_page(@page1).should == true
    editor.can_view_page(@page2).should == true
    editor.ability.can?(:manage_model, "StaffProfile").should == true
    editor.ability.can?(:destroy, @staff1).should == true
    editor.ability.can?(:destroy, @staff2).should == true
    editor.ability.can?(:destroy, @staff3).should == true
    editor.ability.can?(:destroy, @page).should == true

    editor.ability.can?(:destroy, asset1).should == true
    editor.ability.can?(:destroy, asset2).should == true
    

    #contributor authorization
    contributor.ability.can?(:manage_object, @page).should == false
    contributor.ability.can?(:manage_model, "StaffProfile").should == false

    contributor.authorizations.create(:authorizable_type => "StaffProfile")
    contributor.ability.can?(:manage_model, "StaffProfile").should == false
    contributor.authorizations.first.update_attributes(:allow => true)
    contributor.ability.can?(:destroy, @staff).should == false
    contributor.ability.can?(:destroy, @staff1).should == true
    contributor.ability.can?(:destroy, @staff2).should == false
    contributor.ability.can?(:destroy, @staff3).should == false
    contributor.ability.can?(:destroy, @page).should == false
    contributor.ability.can?(:manage_model, "StaffProfile").should == true
    contributor.authorizations.first.destroy
    contributor.ability.can?(:manage_model, "StaffProfile").should == false

    contributor.authorizations.create(:authorizable_type => "Gluttonberg::Page")
    contributor.ability.can?(:manage_object, @page).should == false
    contributor.ability.can?(:manage_object, @page1).should == false
    contributor.ability.can?(:manage_object, @page2).should == false
    contributor.can_view_page(@page).should == false
    contributor.can_view_page(@page1).should == false
    contributor.can_view_page(@page2).should == false
    contributor.authorizations.first.update_attributes(:authorizable_id => @page1.id)
    contributor.ability.can?(:manage_object, @page).should == false
    contributor.ability.can?(:manage_object, @page1).should == true
    contributor.ability.can?(:manage_object, @page2).should == true

    contributor.can_view_page(@page).should == true
    contributor.can_view_page(@page1).should == true
    contributor.can_view_page(@page2).should == true

    contributor.ability.can?(:destroy, asset1).should == true
    contributor.ability.can?(:destroy, asset2).should == false

    super_admin.destroy
    admin.destroy
    editor.destroy
    contributor.destroy
  end

end
