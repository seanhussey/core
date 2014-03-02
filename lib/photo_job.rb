require 'sidekiq'

class PhotoJob
  include Sidekiq::Worker

  def perform(photo_id)
    asset = Gluttonberg::Asset.find(photo_id)
    p "Generating thumbnails for #{asset.file_name}"
    if !File.exist?(asset.tmp_location_on_disk) && !File.exist?(asset.tmp_original_file_on_disk)
      asset.download_asset_to_tmp_file
    end
    Gluttonberg::Library::Processor::Image.process(asset, false)
    asset.remove_file_from_tmp_storage
  end

end
