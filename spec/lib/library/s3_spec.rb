require 'spec_helper'

module Gluttonberg
  describe Library::Storage::S3 do

    before :all do
      Gluttonberg.send(:remove_const, 'Asset')
      load File.join(ENGINE_RAILS_ROOT, 'lib/gluttonberg/library.rb')
      load File.join(ENGINE_RAILS_ROOT, 'app/models/gluttonberg/asset.rb')
      S3_DUMMY_ROOT = File.join(ENGINE_RAILS_ROOT,"spec/dummy/tmp/fakes3_root/local-bucket/public/test_assets")
      Rails.configuration.asset_storage = :s3
      Asset.initialize_storage
      Setting.generate_common_settings
      Setting.update_settings({"s3_key_id" => "YOUR_ACCESS_KEY_ID"})
      Setting.update_settings({"s3_access_key" => "YOUR_SECRET_ACCESS_KEY"})
      Setting.update_settings({"s3_server_url" => "localhost:4567"})
      Setting.update_settings({"s3_bucket" => "local-bucket"})

      @s3_bucket_handle = AWS::S3.new({ 
        :access_key_id => Setting.get_setting("s3_key_id"), 
        :secret_access_key => Setting.get_setting("s3_key_id"), 
        :s3_endpoint => 'local.s3.endpoint',
        :s3_port => 4567,
        :use_ssl => false
      }).buckets[Setting.get_setting("s3_bucket")]

      @file = GbFile.new(File.join(RSpec.configuration.fixture_path, "assets/gb_banner.jpg"))
      @file.original_filename = "gluttonberg_banner.jpg"
      @file.content_type = "image/jpeg"
      @file.size = 300

      @collection1 = AssetCollection.new(:name => "Collection1")
      @collection2 = AssetCollection.new(:name => "Collection2")
      @collection3 = AssetCollection.new(:name => "Collection3")

      @param = {
        :name=>"temp file",
        :asset_collections => [ @collection1 , @collection3 ],
        :file=> @file,
        :description=>"<p>test</p>"
      }

      Gluttonberg::Library.bootstrap

      @asset = Asset.new( @param )
    end

    after :all do
      clean_all_data
      Rails.configuration.asset_storage = :filesystem
      Gluttonberg.send(:remove_const, 'Asset')
      load File.join(ENGINE_RAILS_ROOT, 'lib/gluttonberg/library.rb')
      load File.join(ENGINE_RAILS_ROOT, 'app/models/gluttonberg/asset.rb')
      Asset.initialize_storage
      FileUtils.rm_rf(S3_DUMMY_ROOT)
    end

    it "should transfer file to s3." do
      asset = Asset.new( @param )
      asset.instance_variable_set(:@bucket,  @s3_bucket_handle)
      status = asset.save
      status.should == true
      
      temp_asset_directory = File.join(S3_DUMMY_ROOT, asset.asset_hash)
      temp_file_path = File.join(temp_asset_directory, asset.file_name)
      File.exists?(temp_file_path).should == true

      asset.destroy
    end
  end
end