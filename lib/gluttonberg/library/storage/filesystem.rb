module Gluttonberg
  module Library
    module Storage
      module Filesystem

        module ClassMethods
          # It run when the engine is loaded. It makes sure that all the required
          # directories for storing assets are in the public dir, creating them if
          # they are missing. It also stores the various paths so they can be
          # retreived using the assets_dir method.
          def self.storage_setup
            Library.set_asset_root(File.join(Rails.root, "public/user_assets"), File.join(Rails.root, "public/user_assets"), File.join(Rails.root, "public/test_assets"))
            FileUtils.mkdir(Library.root) unless File.exists?(Library.root) || File.symlink?(Library.root)
          end
        end

        module InstanceMethods

          # The generated directory where this file is located. If it is an image
          # it’s thumbnails will be stored here as well.
          def directory
            Filesystem::ClassMethods.storage_setup if Library.root.blank?
            Library.root + "/" + self.asset_hash
          end

          def tmp_directory
            Filesystem::ClassMethods.storage_setup if Library.tmp_root.blank?
            Library.tmp_root + "/" + self.asset_hash
          end

          def assets_directory_public_url
            "/user_assets"
          end

          def make_backup
            unless File.exist?(original_file_on_disk)
              FileUtils.cp location_on_disk, original_file_on_disk
              FileUtils.chmod(0755,original_file_on_disk)
            end
          end

          def remove_file_from_storage
            if File.exists?(directory)
              FileUtils.rm_r(directory)
            end
          end

          def remove_file_from_tmp_storage
            # just dummy method. As we don't need to remove because tmp and actual folder is same for filesystem
          end

          def download_asset_to_tmp_file
            # just dummy method. As we don't need to download file for filesystem storage
          end

          def update_file_on_storage
            if file
              FileUtils.mkdir(directory) unless File.exists?(directory)
              FileUtils.cp file.tempfile.path, location_on_disk
              FileUtils.chmod(0755, location_on_disk)

              #  new file has been upload, if its image generate thumbnails, if mp3 collect sound info.
              asset_processing
            end
          end

          def move_tmp_file_to_actual_directory(file_name , tmp_file_dirty=true)
            if self.file_dirty == true
              self.file_dirty = false
            end
          end

          # def write_file_to_disc(src_file_path , )
          # end
        end #InstanceMethods

      end #Filesystem
    end #Storage
  end #Library
end #Gluttonberg