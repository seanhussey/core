module Gluttonberg
  class AssetBulkImport
    # makes a new folder (name of the folder is current time stamp) inside tmp folder
    # open zip folder
    # iterate on opened zip folder and make assets for each entry using  make_asset_for_entry method
    # removes directory which we made inside tmp folder
    # also removes zip tmp file
    def self.open_zip_file_and_make_assets(asset_params, current_user)
      new_assets = []
      zip = asset_params[:file]
      dir = File.join(Rails.root,"tmp")
      dir = File.join(dir,Time.now.to_i.to_s)

      FileUtils.mkdir_p(dir)

      begin
        Zip::ZipFile.open(zip.tempfile.path).each do |entry|
          asset = self.make_asset_for_entry(asset_params, current_user, entry , dir)
          new_assets << asset if !asset.blank? && asset.kind_of?(Gluttonberg::Asset)
        end
        zip.tempfile.close
      rescue => e
        Rails.logger.info e
      end
      FileUtils.rm_r(dir)
      new_assets
    end

    # taskes zip_entry and dir path. makes assets if its valid then also add it to @new_assets list
    # its responsible of extracting entry and its deleting it.
    # it use file name for making asset.
    def self.make_asset_for_entry(asset_params, current_user, entry , dir)
      begin
        unless entry.name.starts_with?("._") || entry.name.starts_with?("__") || entry.name.split("/").last.starts_with?(".") || entry.name.split("/").last.starts_with?("__") || entry.directory?
          entry_name = entry.name.gsub("/", "-")
          filename = File.join(dir,entry_name)
          entry.extract(filename)
          file = GbFile.init(filename , entry)
          asset_name_with_extention = entry_name.split(".").first
          asset_name_with_extention = asset_name_with_extention.humanize
          asset_name_with_extention = asset_name_with_extention.gsub('-',' ')
          asset = Asset.new(asset_params.merge( :name => asset_name_with_extention ,  :file => file ) )
          asset.user_id = current_user.id
          status = asset.save
          file.close
          FileUtils.remove_file(filename)
          status ? asset : nil
        end
      rescue => e
        Rails.logger.info e
      end
    end
  end #class
end