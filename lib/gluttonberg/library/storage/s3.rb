module Gluttonberg
  module Library
    module Storage
      module S3
        module ClassMethods
          # It run when the engine is loaded. It makes sure that all the required
          # directories for storing assets are in the public dir, creating them if
          # they are missing. It also stores the various paths so they can be
          # retreived using the assets_dir method.
          TEMP_ASSET_DIRECTORY = "tmp/user_assets"
          def self.storage_setup
            Library.set_asset_root("user_assets", TEMP_ASSET_DIRECTORY, "public/test_assets")
            FileUtils.mkdir(Library.root) unless File.exists?(Library.root) || File.symlink?(Library.root)
            FileUtils.mkdir(Library.tmp_root) unless File.exists?(Library.tmp_root) || File.symlink?(Library.tmp_root)
          end

          def self.s3_server_url
            Gluttonberg::Setting.get_setting("s3_server_url")
          end

          def self.s3_bucket_name
            Gluttonberg::Setting.get_setting("s3_bucket")
          end

          def self.s3_server_key_id
            Gluttonberg::Setting.get_setting("s3_key_id")
          end

          def self.s3_server_access_key
            Gluttonberg::Setting.get_setting("s3_access_key")
          end

          def self.bucket_handle
            key_id = S3::ClassMethods.s3_server_key_id
            key_val = S3::ClassMethods.s3_server_access_key
            s3_server_url = S3::ClassMethods.s3_server_url
            s3_bucket = S3::ClassMethods.s3_bucket_name
            if !key_id.blank? && !key_val.blank? && !s3_server_url.blank? && !s3_bucket.blank?
              s3 = Aws::S3.new(key_id, key_val, {:server => s3_server_url})
              bucket = s3.bucket(s3_bucket)
            else
              nil
            end
          end

          #takes file from public/assets folder and upload to s3 if s3 info is given in CMS settings
          def self.migrate_file_to_s3(asset_hash , file_name)
            bucket = bucket_handle
            unless bucket.blank?
              local_file = "public/user_assets/" + asset_hash + "/" + file_name
              key_for_s3 = "user_assets/" + asset_hash + "/" + file_name
              date = Time.now+1.years
              key = bucket.key(key_for_s3, true)
              asset = Gluttonberg::Asset.where(:asset_hash => asset_hash).first
              unless asset.blank?
                puts " Copying #{local_file} to #{S3::ClassMethods.s3_bucket_name}"
                unless asset.mime_type.blank?
                  key.put(File.open(local_file), 'public-read', {"Expires" => date.rfc2822, "content-type" => asset.mime_type})
                else
                  key.put(File.open(local_file), 'public-read', {"Expires" => date.rfc2822})
                end
                asset.update_attributes(:copied_to_s3 => true)
              end
              puts "Copied"
            end
          end

        end

        module InstanceMethods

          def bucket_handle
            unless @bucket.blank?
              @bucket
            else
              @bucket = S3::ClassMethods.bucket_handle
            end
          end

          # The generated directory where this file is located.
          def directory
            S3::ClassMethods.storage_setup if Library.root.blank?
            Library.root + "/" + self.asset_hash
          end

          # The generated tmp directory where we will locate this file temporarily for processing.
          def tmp_directory
            S3::ClassMethods.storage_setup if Library.tmp_root.blank?
            Library.tmp_root + "/" + self.asset_hash
          end

          def s3_bucket_root_url
            "http://#{S3::ClassMethods.s3_server_url}/#{S3::ClassMethods.s3_bucket_name}"
          end

          def assets_directory_public_url
            "#{s3_bucket_root_url}/user_assets"
          end

          def make_backup
            unless File.exist?(tmp_original_file_on_disk)
              FileUtils.cp tmp_location_on_disk, tmp_original_file_on_disk
              FileUtils.chmod(0755,tmp_original_file_on_disk)
              move_tmp_file_to_actual_directory("original_" + file_name , true)
            end
          end

          def remove_file_from_storage
            remove_file_from_tmp_storage
            remove_asset_folder_from_s3
          end

          def remove_file_from_tmp_storage
            if File.exists?(tmp_directory)
              puts "Remove assset folder from tmp storage (tmp_directory)"
              FileUtils.rm_r(tmp_directory)
            end
          end

          def update_file_on_storage
            if file
              FileUtils.mkdir(tmp_directory) unless File.exists?(tmp_directory)
              FileUtils.cp file.tempfile.path, tmp_location_on_disk
              FileUtils.chmod(0755, tmp_location_on_disk)

              move_tmp_file_to_actual_directory(file_name , false)
              #  new file has been upload, if its image generate thumbnails, if mp3 collect sound info.
              asset_processing
              # delete local tmp folder
              remove_file_from_tmp_storage
            end
          end

          def move_tmp_file_to_actual_directory(file_name , tmp_file_dirty=true)
            if self.file_dirty == true || tmp_file_dirty == true
              copy_file_to_s3(file_name)
              self.file_dirty = false
            end
          end

          #takes file from tmp folder and upload to s3 if s3 info is given in CMS settings
          def copy_file_to_s3(file_name)
            bucket = bucket_handle
            unless bucket.blank?
              local_file = self.tmp_directory + "/" + file_name
              folder = self.asset_hash
              date = Time.now+1.years
              puts "Copying #{file_name} (#{local_file}) to #{S3::ClassMethods.s3_bucket_name}"
              key = bucket.key(self.directory + "/" + file_name, true)
              unless self.mime_type.blank?
                key.put(File.open(local_file), 'public-read', {"Expires" => date.rfc2822, "content-type" => self.mime_type})
              else
                key.put(File.open(local_file), 'public-read', {"Expires" => date.rfc2822})
              end
              self.update_attributes(:copied_to_s3 => true)
              puts "Copied"
            end
          end



          # TODO
          def remove_file_from_s3(file_name)
          end

          def remove_asset_folder_from_s3
            bucket = bucket_handle
            unless bucket.blank?
              bucket.delete_folder(self.directory)
            end
          end

          def download_asset_to_tmp_file
            download_orginal_file_from_s3
          end

          def download_orginal_file_from_s3
            FileUtils.mkdir(self.tmp_directory) unless File.exists?(self.tmp_directory)
            bucket = bucket_handle
            key = bucket.key(self.location_on_disk)
            File.open(self.tmp_location_on_disk, "w") do |f|
              f.write(key.get)
            end
            key = bucket.key(self.original_file_on_disk)
            if key.exists?
              File.open(self.tmp_original_file_on_disk, "w") do |f|
                f.write(key.get)
              end
            end
          end

        end #InstanceMethods
      end #S3
    end #Storage
  end #Library
end #Gluttonberg