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
          audio = AudioAssetAttribute.find( :first , :conditions => {:asset_id => asset.id})

          begin
            #open mp3 file
            Mp3Info.open(location_on_disk) do |mp3|
              if audio.blank?
                AudioAssetAttribute.create( :asset_id => asset.id , :length => mp3.length , :title => mp3.tag.title , :artist => mp3.tag.artist , :album => mp3.tag.album , :tracknum => mp3.tag.tracknum)
              else
                audio.update_attributes( {:length => mp3.length, :genre =>"" , :title => mp3.tag.title , :artist => mp3.tag.artist , :album => mp3.tag.album , :tracknum => mp3.tag.tracknum })
              end
            end
            if Gluttonberg::Setting.get_setting("audio_assets") == "Enable"
              Delayed::Job.enqueue AudioJob.new(asset.id)
            end
          rescue => detail
            # if exception occurs and asset has some attributes, then remove them.
            unless audio.blank?
              audio.update_attributes( {:length => nil , :title => nil , :artist => nil , :album => nil , :tracknum => nil })
            end
          end

        end #collect_mp3_info

      end
    end
  end
end