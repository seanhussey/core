require 'spec_helper'

module Gluttonberg

  describe AssetCollection do

    before :all do
    end

    after :all do
      clean_all_data
    end

    it "should have 2 collections" do
      AssetCollection.create(:name => "Collection1")
      AssetCollection.create(:name => "Collection2")
      AssetCollection.count.should == 2
    end


    it "should not create collection without name" do
      AssetCollection.create(:name => "")
      @collections = AssetCollection.all
      AssetCollection.count.should == 0
    end

    it "should not create duplicate collection" do
      AssetCollection.create(:name => "Collection1")
      begin
        AssetCollection.create(:name => "Collection1")
      rescue
      end
      @collections = AssetCollection.where(:name => "Collection1")
      @collections.count.should == 1
    end

    it "should process new collections and merge with selection collections" do
      params = {
        :asset => {
          :asset_collection_ids => []
        },
        :new_collection => {
          :new_collection_name => ""
        }
      }

      current_user = User.new({
        :first_name => "First",
        :email => "valid_user@test.com",
        :password => "password1",
        :password_confirmation => "password1"
      })
      current_user.role = "super_admin"
      current_user.save
      AssetCollection.process_new_collection_and_merge(params, current_user).should == []
      params[:asset][:asset_collection_ids] = ""
      AssetCollection.process_new_collection_and_merge(params, current_user).should == []
      params[:asset][:asset_collection_ids] = "null"
      AssetCollection.process_new_collection_and_merge(params, current_user).should == []
      params[:asset][:asset_collection_ids] = "undefined"
      AssetCollection.process_new_collection_and_merge(params, current_user).should == []
      params[:asset][:asset_collection_ids] = "1,2"
      AssetCollection.process_new_collection_and_merge(params, current_user).should == ["1","2"]
      params[:asset][:asset_collection_ids] = [1,2]
      AssetCollection.process_new_collection_and_merge(params, current_user).should == [1,2]
      params[:new_collection][:new_collection_name] = "New Collection"
      AssetCollection.process_new_collection_and_merge(params, current_user).length.should == 3
    end

  end

end