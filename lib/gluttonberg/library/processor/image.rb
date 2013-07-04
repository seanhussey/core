module Gluttonberg
  module Library
    module Processor
      class Image

        attr_accessor :asset

        def self.process(asset_obj)
          if asset_obj.asset_type.asset_category.name == "image"
            processor = self.new
            processor.asset = asset_obj
            processor.generate_thumb_and_proper_resolution
          end
        end

        # Generates thumbnails for images, but also additionally checks to see
        # if the uploaded image exceeds the specified maximum, in which case it will resize it down.
        def generate_thumb_and_proper_resolution
          generate_proper_resolution
          generate_image_thumbnails
        end

        def suggested_measures(object , required_geometry)
          required_geometry_tokens = required_geometry.delete("#").split("x")
          actual_width = object.width.to_i
          actual_height = object.height.to_i
          required_width = required_geometry_tokens.first.to_i
          required_height = required_geometry_tokens.last.to_i

          ratio_required = required_width.to_f / required_height
          ratio_actual = actual_width.to_f / actual_height

          crossover_ratio = required_height.to_f / actual_height
          crossover_ratio2 = required_width.to_f / actual_width

          if(crossover_ratio < crossover_ratio2 )
            crossover_ratio = crossover_ratio2
          end

          projected_height = actual_height * crossover_ratio

          if(projected_height < required_height )
            required_width = required_width * (1 + (ratio_actual -  ratio_required ) )
          end
          projected_width = actual_width * crossover_ratio

          "#{(projected_width).ceil}x#{(projected_width/ratio_actual).ceil}"
        end

        def generate_cropped_image(x , y , w , h, image_type)
          asset_thumb = asset.asset_thumbnails.find_or_initialize_by_thumbnail_type(image_type.to_s)
          asset_thumb.user_generated = true
          asset_thumb.save

          file_name = "#{asset.class.sizes[image_type.to_sym][:filename]}.#{asset.file_extension}"
          image = read_image_file(asset)
          thumb_defined_width = asset.class.sizes[image_type.to_sym][:geometry].split('x').first#.to_i
          scaling_percent = (thumb_defined_width.to_i/(w.to_i*1.0))*100
          image.arguments << " -crop #{w}x#{h}+#{x}+#{y} +repage"
          if scaling_percent != 1.0
            image.arguments << " -resize #{scaling_percent}%"
          end
          image.save File.join(asset.tmp_directory, file_name)
          asset.move_tmp_file_to_actual_directory(file_name , true)
        end

        # Create thumbnailed versions of image attachements.
        def generate_image_thumbnails
          asset.class.sizes.each_pair do |name, config|
            asset_thumb = asset.asset_thumbnails.where({
              :thumbnail_type => name.to_s,
              :user_generated => true
            }).first
            _generate_image_thumbnail(name, config) if asset_thumb.blank?
          end # sizes loop

          asset.update_attribute(:custom_thumbnail , true)
        end



        def generate_proper_resolution
          asset.make_backup
          image = read_image_file(asset)

          actual_width = image.width.to_i
          actual_height = image.height.to_i

          asset.update_attributes( :width => actual_width, :height => actual_height)

          image.resize asset.class.max_image_size
          image.save File.join(asset.tmp_directory, asset.file_name)
          asset.move_tmp_file_to_actual_directory(asset.file_name , true)
          # remove mp3 info if any image have. it may happen in the case of updating asset from mp3 to image
          audio = AudioAssetAttribute.where(:asset_id => asset.id).first
          audio.destroy unless audio.blank?
        end

        private
          def _generate_image_thumbnail(name, config)
            image = read_image_file(asset)

            file_name = "#{config[:filename]}.#{asset.file_extension}"
            _generate_image_thumbnail_resize(name, config, image, asset, file_name)
            asset.move_tmp_file_to_actual_directory(file_name, true)
          end

          def _generate_image_thumbnail_resize(name, config, image, asset, file_name)
            if config[:geometry].include?("#")
              begin
                image.resize(suggested_measures(image, config[:geometry]))
                image.arguments << " -gravity Center  -crop #{config[:geometry].delete("#")}+0+0 +repage #{config[:grayscale] && config[:grayscale] == true ? "-colorspace Gray":""}"
              rescue => e
                puts e
              end
            else
              image.resize config[:geometry]
              image.arguments << "-colorspace Gray" if config[:grayscale] && config[:grayscale] == true
            end
            image.save File.join(asset.tmp_directory, file_name)
          end

          def read_image_file(asset)
            begin
              image = QuickMagick::Image.read(asset.tmp_original_file_on_disk).first
            rescue => e
              image = QuickMagick::Image.read(asset.tmp_location_on_disk).first
            end
            image
          end


      end
    end
  end
end