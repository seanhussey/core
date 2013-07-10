require 'sidekiq'

class AudioJob
  include Sidekiq::Worker

  def perform(audio_id)
    asset = Gluttonberg::Asset.find(audio_id)
    if Gluttonberg::Setting.get_setting("audio_assets") == "Enable"
      if !Gluttonberg::Setting.get_setting("s3_key_id").blank? && !Gluttonberg::Setting.get_setting("s3_access_key").blank? && !Gluttonberg::Setting.get_setting("s3_server_url").blank? && !Gluttonberg::Setting.get_setting("s3_bucket").blank?
        asset.copy_audios_to_s3
      end
    end
  end

  def save_asset_to(asset)
    Rails.root.to_s + "/public" + asset.asset_folder_path
  end

end
