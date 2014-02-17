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
      dir = create_tmp_folder
      begin
        Zip::File.open(zip.tempfile.path).each do |entry|
          asset = self.make_asset_for_entry(asset_params, current_user, entry , dir)
          new_assets << asset if asset && asset.kind_of?(Gluttonberg::Asset)
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
        unless self.hidden_file_or_directory?(entry)
          entry_name = entry.name.gsub("/", "-")
          filename = File.join(dir,entry_name)
          entry.extract(filename)
          file = GbFile.init(filename)
          asset = prepare_asset(entry_name, file, current_user, asset_params)
          file.close
          FileUtils.remove_file(filename)
          asset
        end
      rescue => e
        Rails.logger.info e
      end
    end

    private
      def self.create_tmp_folder
        dir = File.join(Rails.root,"tmp")
        dir = File.join(dir,Time.now.to_i.to_s)
        FileUtils.mkdir_p(dir)
      end

      def self.prepare_asset(entry_name, file, current_user, asset_params)
        asset_name_with_extention = entry_name.split(".").first
        asset_name_with_extention = asset_name_with_extention.humanize
        asset_name_with_extention = asset_name_with_extention.gsub('-',' ')
        asset = Asset.new(asset_params.merge( :name => asset_name_with_extention ,  :file => file ) )
        asset.user_id = current_user.id
        asset.save ? asset : nil
      end

      def self.hidden_file_or_directory?(entry)
        self.hidden_file?(entry.name) || entry.directory?
      end

      def self.hidden_file?(file_name)
        name = file_name.split("/").last
        name.starts_with?(".") || name.starts_with?("__")
      end
  end #class
end