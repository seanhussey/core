module Gluttonberg
  module Library
    # The attachment mixin encapsulates the majority of logic for handling and
    # processing uploads. It exists here in a mixin rather than in the Asset
    # class purely because it is ultimately the intention to have a different
    # Asset class for each major category of assets e.g. ImageAsset,
    # DocumentAsset.

    module AttachmentMixin

      def self.included(klass)
        klass.class_eval do
          after_destroy  :remove_file_from_storage
          before_save    :generate_reference_hash
          after_save     :update_file_on_storage
          attr_accessor  :file_dirty

          extend ClassMethods
          include InstanceMethods
          extend Library::Config::ImageSizes::ClassMethods
          include Library::Config::ImageSizes::InstanceMethods

          initialize_storage()
        end
      end


      module ClassMethods

        def initialize_storage
          storage_class_name = Rails.configuration.asset_storage.to_s.downcase.camelize
          begin
            storage_module = Gluttonberg::Library::Storage.const_get(storage_class_name)
          rescue NameError
            raise Exception, "Cannot load storage module '#{storage_class_name}'"
          end
          include(storage_module.const_get("InstanceMethods"))
          extend(storage_module.const_get("ClassMethods"))
        end


        # Generate auto titles for those assets without name
        def generate_name
          assets = Asset.find(:all , :conditions => { :name => "" } )
          assets.each do |asset|
            p asset.file_name
            asset.name = asset.file_name.split(".")[0]
            asset.save
          end
          'done' # this just makes the output nicer when running from slice -i
        end

      end #ClassMethods


      module InstanceMethods

        # Setter for the file object. It sanatises the file name and stores in
        # the filename property. It also sets the mime-type and size.
        def file=(new_file)
          unless new_file.blank?
            logger.info("\nFILENAME: #{new_file.original_filename} \n\n")

            # Forgive me this naive sanitisation, I'm still a regex n00b
            clean_filename = new_file.original_filename.split(%r{[\\|/]}).last
            clean_filename = clean_filename.gsub(" ", "_").gsub(/[^A-Za-z0-9\-_.]/, "").downcase

            # _thumb.#{file_extension} is a reserved name for the thumbnailing system, so if the user
            # has a file with that name rename it.
            if (clean_filename == '_thumb_small.#{file_extension}') || (clean_filename == '_thumb_large.#{file_extension}')
              clean_filename = 'thumb.#{file_extension}'
            end

            self.mime_type = new_file.content_type
            self.file_name = clean_filename
            self.size = new_file.size
            @file = new_file
            self.file_dirty = true
          end
        end

        # Returns the file assigned by file=
        def file
          @file
        end

        def file_extension
          file_name.split(".").last
        end

        def asset_folder_path
          directory
        end

        def asset_directory_public_url
          "#{assets_directory_public_url}/#{asset_hash}"
        end

        # Returns the public URL to this asset, relative to the domain.
        def url
          "#{asset_directory_public_url}/#{file_name}"
        end

        # Returns the full path to the file’s location on disk.
        def location_on_disk
          directory + "/" + file_name
        end

        # asset  path in actual assets directory
        def original_file_on_disk
          directory + "/original_" + file_name
        end

        # Returns the full path to the file's location on disk in tmp directory.
        def tmp_location_on_disk
          tmp_directory + "/" + file_name
        end

        # asset full path in tmp directory
        def tmp_original_file_on_disk
          tmp_directory + "/original_" + file_name
        end

        def generate_cropped_image(x , y , w , h, image_type)
          if !File.exist?(self.tmp_location_on_disk) && !File.exist?(self.tmp_original_file_on_disk)
            self.download_asset_to_tmp_file
          end
          processor = Library::Processor::Image.new
          processor.asset = self
          processor.generate_cropped_image(x , y , w , h, image_type)
          self.remove_file_from_tmp_storage
        end

        def asset_processing
          asset_id_to_process = self.id
          asset = Asset.where(:id => asset_id_to_process).first
          if asset
            asset_processors = [Library::Processor::Image , Library::Processor::Audio] #Core processors
            asset_processors << Rails.configuration.asset_processors unless Rails.configuration.asset_processors.blank? #additional processors
            asset_processors = asset_processors.flatten
            unless asset_processors.blank?
              asset_processors.each do |processor|
                processor.process(asset)
              end
            end
          end
        end # asset_processing


        private

          def generate_reference_hash
            unless self.asset_hash
              self.asset_hash = Digest::SHA1.hexdigest(Time.now.to_s + file_name)
            end
          end
      end
    end # AttachmentMixin
  end #Library
end # Gluttonberg
