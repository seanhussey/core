require 'rubygems'

ASSET_LIBRARY_BASE_DIR = File.join(File.dirname(__FILE__), "../..")

namespace :gluttonberg do
  namespace :library do

    desc "Try and generate thumbnails for all assets"
    task :create_thumbnails => :environment do
      category = Gluttonberg::AssetCategory.find( :first , :conditions =>{  :name => "image" } )
      if category
        assets = category.assets #Asset.all
        assets.each do |asset|
          p "thumb-nailing '#{asset.file_name}'  "
          if !File.exist?(asset.tmp_location_on_disk) && !File.exist?(asset.tmp_original_file_on_disk)
            asset.download_asset_to_tmp_file
          end
          # asset.generate_image_thumb
          # asset.generate_proper_resolution
          # asset.save
          Gluttonberg::Library::Processor::Image.process(asset)
          asset.remove_file_from_tmp_storage
        end
      end
    end

    desc "Rebuild AssetType information and reassociate with existing Assets"
    task :bootstrap => :environment do
      Gluttonberg::Library.bootstrap
    end

    desc "Rebuild AssetType information and reassociate with existing Assets"
    task :rebuild_asset_types => :environment do
      Gluttonberg::Library.rebuild
    end

    desc "Assign file_name as name of those asset whose name is null"
    task :generate_asset_names => :environment do
      Gluttonberg::Asset.generate_name
    end

    desc "Make assets from files in bulks folder"
    task :generate_asset_from_bulks_folder => :environment do
      Gluttonberg::Asset.create_assets_from_ftp
    end

    desc "Update assets synopsis through csv"
    task :update_assets_synopsis_from_csv => :environment do
      Gluttonberg::Asset.update_assets_synopsis_from_csv
    end

    desc "Migrate assets from public/user_assets folder to S3"
    task :migrate_assets_to_s3 => :environment do
      Dir.entries("public/user_assets").each do |asset_folder|
        if !asset_folder.include?(".DS_Store") && File.directory?("public/user_assets/" + asset_folder)
          Dir.entries("public/user_assets/"+asset_folder).each do |asset_file|
            if !asset_file.include?(".DS_Store") && !File.directory?("public/user_assets/" + asset_folder+"/"+asset_file)
              begin
                Gluttonberg::Library::Storage::S3::ClassMethods.migrate_file_to_s3(asset_folder , asset_file)
              rescue => e
                puts "Error: #{e.message}"
              end
            end
          end
        end
      end
    end

  end
end