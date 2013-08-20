require 'spec_helper'

module Gluttonberg
  describe Admin::Content::AutoSaveController do
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
      Gluttonberg::Setting.generate_common_settings
      @asset = create_image_asset
      
    end

    after :all do
      clean_all_data
    end

    describe "POST create" do
      it "save draft" do
        controller.instance_variable_set(:@current_user, @current_user)
        @page = Page.create! :name => 'first name', :description_name => 'generic_page'
        page_localization = @page.current_localization
        
        actual_content = prepare_content_data(page_localization.contents, @asset)        
        content_params = { :gluttonberg_page_localization => actual_content}
        
        post :create, {:model_name => page_localization.class.name, :id => page_localization.id}.merge(content_params)
        expect(response.status).to eq(200)
        expect(response.body).to eq("\"OK\"")
        auto_save = AutoSave.where({:auto_save_able_id => page_localization.id, :auto_save_able_type => page_localization.class.name}).first
        auto_save.should_not be_nil
        auto_save.data.should eql(actual_content.to_json)
      end
    end

    # describe "GET retrieve" do
    #   it "retrieve data" do
    #     controller.instance_variable_set(:@current_user, @current_user)
    #     put :update, {:id => @staff_profile.id}
    #     expect(response.status).to eq(200)
    #     feed = Gluttonberg::Feed.last
    #     feed.should_not be_nil
    #     feed.feedable_type.should == "StaffProfile"
    #     feed.title.should == "Nick"
    #     feed.action_type.should == "updated"
    #     feed.user.id.should == @current_user.id
    #   end
    # end

    # describe "DELETE destroy" do
    #   it "destroy draft" do
    #     controller.instance_variable_set(:@current_user, @current_user)
    #     delete :destroy, {:id => @staff_profile.id}
    #     expect(response.status).to eq(200)
    #     feed = Gluttonberg::Feed.last
    #     feed.should_not be_nil
    #     feed.feedable_type.should == "StaffProfile"
    #     feed.title.should == "Nick"
    #     feed.action_type.should == "deleted"
    #     feed.user.id.should == @current_user.id
    #     create_staff
    #   end
    # end


    private
        
  end
end