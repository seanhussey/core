module Gluttonberg
  module Library
    module Config
      # Mixin which provides image sizes functionality to asset model
      module ImageSizes
        extend ActiveSupport::Concern

        # Default sizes used when thumbnailing an image.
        DEFAULT_THUMBNAILS = {
          :small_thumb => {:label => "Small Thumb", :filename => "_thumb_small", :geometry => "360x268#" },
          :large_thumb => {:label => "Large Thumb", :filename => "_thumb_large", :geometry => "360x268>"},
          :backend_logo => {:label => "Backend Logo", :filename => "_backend_logo", :geometry => "1000x30"}
        }

        # The default max image size. This can be overwritten on a per project
        # basis via the rails configuration.
        MAX_IMAGE_SIZE = "2000x2000>" #Resize image to have specified area in pixels. Aspect ratio is preserved.

        module ClassMethods
          # Returns a collection of thumbnail definitions — sizes, filename etc. —
          # which is a merge of defaults and any custom thumbnails defined by the
          # user.
          def sizes
            @thumbnail_sizes ||= if Rails.configuration.thumbnails
              Rails.configuration.thumbnails.merge(DEFAULT_THUMBNAILS)
            else
              DEFAULT_THUMBNAILS
            end
          end

          # Returns the max image size as a hash containing :width and :height.
          # May be the default, or the value configured for a particular project.
          def max_image_size
            Rails.configuration.max_image_size || MAX_IMAGE_SIZE
          end

        end #ClassMethods

        # InstanceMethods
        # Returns the URL for the specified image size.
        def url_for(name=nil)
          if name.blank?
            url
          elsif self.class.sizes.has_key? name
            filename = self.class.sizes[name.to_sym][:filename]
            "#{asset_directory_public_url}/#{filename}.#{file_extension}"
          end
        end

        # Returns the public URL to the asset’s small thumbnail — relative
        # to the domain.
        def thumb_small_url
          url_for(:small_thumb) if category.downcase == "image"
        end

        # Returns the public URL to the asset’s large thumbnail — relative
        # to the domain.
        def thumb_large_url
          url_for(:large_thumb) if category.downcase == "image"
        end
      end
    end
  end
end