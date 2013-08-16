require 'spec_helper'

describe Admin::StaffProfilesController do
  before :all do
    @current_user = User.new({
      :first_name => "First",
      :email => "valid_user@test.com",
      :password => "password1",
      :password_confirmation => "password1"
    })
    @current_user.role = "super_admin"
    @current_user.save
    @current_user.id.should_not be_nil
    @locale = Gluttonberg::Locale.generate_default_locale
    create_staff
  end

  after :all do
    clean_all_data
  end

  describe "POST create" do
    it "log_create" do
      controller.instance_variable_set(:@current_user, @current_user)
      post :create
      expect(response.status).to eq(200)
      feed = Gluttonberg::Feed.last
      feed.should_not be_nil
      feed.feedable_type.should == "StaffProfile"
      feed.title.should == "Abdul"
      feed.action_type.should == "created"
      feed.user.id.should == @current_user.id
    end
  end

  describe "PUT update" do
    it "log_update" do
      controller.instance_variable_set(:@current_user, @current_user)
      put :update, {:id => @staff_profile.id}
      expect(response.status).to eq(200)
      feed = Gluttonberg::Feed.last
      feed.should_not be_nil
      feed.feedable_type.should == "StaffProfile"
      feed.title.should == "Nick"
      feed.action_type.should == "updated"
      feed.user.id.should == @current_user.id
    end
  end

  describe "DELETE destroy" do
    it "log_destroy" do
      controller.instance_variable_set(:@current_user, @current_user)
      delete :destroy, {:id => @staff_profile.id}
      expect(response.status).to eq(200)
      feed = Gluttonberg::Feed.last
      feed.should_not be_nil
      feed.feedable_type.should == "StaffProfile"
      feed.title.should == "Nick"
      feed.action_type.should == "deleted"
      feed.user.id.should == @current_user.id
      create_staff
    end
  end


  private
      def create_staff
        @staff_profile = StaffProfile.new_with_localization({
          :name => "Nick"
        })
        @staff_profile.save
      end


end
