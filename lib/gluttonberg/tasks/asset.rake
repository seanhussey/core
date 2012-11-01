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
          asset.generate_image_thumb
          asset.generate_proper_resolution
          asset.save
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

  end
end