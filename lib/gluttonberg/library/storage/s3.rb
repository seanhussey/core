module Gluttonberg
  module Library
    module Storage
      module S3
        extend ActiveSupport::Concern

        module ClassMethods
          # It run when the engine is loaded. It makes sure that all the required
          # directories for storing assets are in the public dir, creating them if
          # they are missing. It also stores the various paths so they can be
          # retreived using the assets_dir method.
          TEMP_ASSET_DIRECTORY = "tmp/user_assets"
          def storage_setup
            Library.set_asset_root("user_assets", TEMP_ASSET_DIRECTORY, "public/test_assets")
            FileUtils.mkdir(Library.root) unless File.exists?(Library.root) || File.symlink?(Library.root)
            FileUtils.mkdir(Library.tmp_root) unless File.exists?(Library.tmp_root) || File.symlink?(Library.tmp_root)
          end

          def s3_server_url
            Gluttonberg::Setting.get_setting("s3_server_url")
          end

          def s3_bucket_name
            Gluttonberg::Setting.get_setting("s3_bucket")
          end

          def s3_server_key_id
            Gluttonberg::Setting.get_setting("s3_key_id")
          end

          def s3_server_access_key
            Gluttonberg::Setting.get_setting("s3_access_key")
          end

          def bucket_handle
            key_id = self.s3_server_key_id
            key_val = self.s3_server_access_key
            s3_server_url = self.s3_server_url
            s3_bucket = self.s3_bucket_name
            if !key_id.blank? && !key_val.blank? && !s3_server_url.blank? && !s3_bucket.blank?
              s3 = AWS::S3.new({
                :access_key_id => key_id,
                :secret_access_key => key_val,
                :server => s3_server_url
              })
              bucket = s3.buckets[s3_bucket]
            else
              nil
            end
          end

          #takes file from public/assets folder and upload to s3 if s3 info is given in CMS settings
          def migrate_file_to_s3(asset_hash , file_name, mime_type='')
            bucket = bucket_handle
            if bucket != nil
              key_for_s3 = "user_assets/" + asset_hash + "/" + file_name
              asset = Gluttonberg::Asset.where(:asset_hash => asset_hash).first
              unless asset.blank?
                local_file = asset.tmp_directory + "/" + file_name
                local_file = "public/user_assets/" + asset_hash + "/" + file_name unless File.exist?(local_file)
                puts " Copying #{local_file} to #{self.s3_bucket_name}"
                self.upload_file_to(asset, bucket.objects[key_for_s3], mime_type, local_file)
                asset.update_attributes(:copied_to_s3 => true)
              end
            end
          end

          def upload_file_to(asset, bucket_key, mime_type, local_file)
            options = {
              :expires => (Time.now+1.years).rfc2822,
              :acl => :public_read
            }
            mime_type = asset.mime_type if mime_type.blank?
            options[:content_type] = mime_type unless mime_type.blank?
            response = bucket_key.write(File.open(File.join((Rails.env == 'test' ? Engine.root : Rails.root),local_file)), options)
            puts "Copied"
          end

        end


        # InstanceMethods

        def bucket_handle
          @bucket ||= self.class.bucket_handle
        end

        def bucket_handle=(handle)
          @bucket = handle
        end

        # The generated directory where this file is located.
        def directory
          self.class.storage_setup if Library.root.blank?
          Library.root + "/" + self.asset_hash
        end

        # The generated tmp directory where we will locate this file temporarily for processing.
        def tmp_directory
          self.class.storage_setup if Library.tmp_root.blank?
          Library.tmp_root + "/" + self.asset_hash
        end

        def s3_bucket_root_url
          "http://#{self.class.s3_server_url}/#{self.class.s3_bucket_name}"
        end

        def assets_directory_public_url
          "#{s3_bucket_root_url}/user_assets"
        end

        def make_backup(replace_backup=true)
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
            puts "Remove assset folder from tmp storage (#{tmp_directory})"
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
            remove_file_from_tmp_storage  unless self.asset_type.asset_category.name == "video"
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
          if bucket
            local_file = self.tmp_directory + "/" + file_name
            puts "Copying #{file_name} (#{local_file}) to #{self.class.s3_bucket_name}"
            bucket_key = bucket.objects[self.directory + "/" + file_name]
            self.class.upload_file_to(self, bucket_key, self.mime_type, local_file)
            self.update_column(:copied_to_s3 , true)
          end
        end

        # This method is used for delayed job
        def copy_audios_to_s3
          copy_file_to_s3(self.file_name)
        end

        # TODO
        def remove_file_from_s3(file_name)
        end

        def remove_asset_folder_from_s3
          bucket = bucket_handle
          unless bucket.blank?
            bucket.objects.with_prefix(self.directory).delete_all
          end
        end

        def download_asset_to_tmp_file
          download_orginal_file_from_s3
        end

        def download_orginal_file_from_s3
          FileUtils.mkdir(self.tmp_directory) unless File.exists?(self.tmp_directory)
          _download_file_from_s3(self.location_on_disk, self.tmp_location_on_disk)
          _download_file_from_s3(self.original_file_on_disk, self.tmp_original_file_on_disk)
        end

        private
          def _download_file_from_s3(src, dest)
            FileUtils.mkdir(self.tmp_directory) unless File.exists?(self.tmp_directory)
            bucket = bucket_handle
            key = bucket.objects[self.location_on_disk]
            if key.exists?
              File.open(self.tmp_original_file_on_disk, "w", encoding: "ASCII-8BIT") do |f|
                key.read do |chunk|
                  f.write(chunk)
                end
              end
            end
          end
      end #S3
    end #Storage
  end #Library
end #Gluttonberg