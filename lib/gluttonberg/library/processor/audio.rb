module Gluttonberg
  module Library
    module Processor
      require "mp3info"
      class Audio
        attr_accessor :asset

        def self.process(asset_obj)
          if asset_obj.asset_type.asset_category.name == "audio"
            self.collect_mp3_info(asset_obj)
          end
        end

        # Collect mp3 files info using Mp3Info gem
        def self.collect_mp3_info(asset)
          begin
            #open mp3 file
            Mp3Info.open(asset.location_on_disk) do |mp3|
              self.update_audio_attributes(asset, mp3)
            end
            self.enqueue_job(asset)
          rescue => detail
            # if exception occurs and asset has some attributes, 
            # then remove them.
            AudioAssetAttribute.where(:asset_id => asset.id).delete_all
          end

        end #collect_mp3_info

        private
          def self.enqueue_job(asset)
            if Gluttonberg::Setting.get_setting("audio_assets") == "Enable"
              AudioJob.perform_async(asset.id)
            end
          end

          def self.update_audio_attributes(asset, mp3)
            audio = asset.audio_asset_attribute
            audio_attrs = {
              :asset_id => asset.id, 
              :length => mp3.length , 
              :title => mp3.tag.title, 
              :artist => mp3.tag.artist, 
              :album => mp3.tag.album, 
              :tracknum => mp3.tag.tracknum,
              :genre =>""
            }
            if audio.blank?
              AudioAssetAttribute.create(audio_attrs)
            else
              audio.update_attributes(audio_attrs)
            end
          end

      end
    end
  end
end
