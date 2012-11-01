module Gluttonberg
 class Setting  < ActiveRecord::Base
   self.table_name = "gb_settings"
   after_save  :update_settings_in_config
   before_destroy :destroy_cache
   attr_accessible :name, :value, :values_list, :help, :category, :row , :delete_able , :enabled
    def self.generate_or_update_settings(settings={})
      settings.each do |key , val |
        obj = self.find(:first , :conditions => {:name => key })
        if obj.blank?
          obj = self.new(:name=> key , :value => val[0] , :row => val[1] , :delete_able => false , :help => val[2] , :values_list => val[3])
          obj.save!
        else
          obj.update_attributes(:name=> key  , :row => val[1] , :delete_able => false , :help => val[2])
        end
      end
    end

    def user_friendly_name
      name.titlecase
    end

    def self.generate_common_settings
      settings = {
        :title => [ "" , 0, "Website Title"],
        :keywords => ["" , 1, "Please separate keywords with a comma."],
        :description => ["" ,2 , "The Description will appear in search engine's result list."],
        :fb_icon => ["" , 3 , "Facebook Icon for the website"],
        :google_analytics => ["", 4, "Google Analytics ID"],
        :comment_notification => ["No" , 5 , "Enable comment notification" , "Yes;No" ],
        :number_of_revisions => ["10" , 6 , "Number of revisions to maintain for versioned contents."],
        :library_number_of_recent_assets => ["15" , 7 , "Number of recent assets in asset library."],
        :number_of_per_page_items => ["20" , 8 , "Number of per page items for any paginated content."],
        :enable_WYSIWYG => ["Yes" , 9 , "Enable WYSIWYG on textareas" , "Yes;No" ],
        :backend_logo => ["" , 10 , "Logo for backend" ] ,
        :restrict_site_access => ["" , 11 , "If this setting is provided then user needs to enter password to access public site."]  ,
        :from_email => ["" , 12 , "This email address is used for 'from' email address for all emails sent through system."],
        :video_assets => ["" , 13 , "FFMPEG settings" , "Enable;Disable"],
        :s3_key_id => ["" , 14 , "S3 Key ID"],
        :s3_access_key => ["" , 15 , "S3 Access Key"],
        :s3_server_url => ["" , 16 , "S3 Server URL"],
        :s3_bucket => ["" , 17 , "S3 Bucket Name"],
        :audio_assets => ["" , 18 , "Audio settings" , "Enable;Disable"]
      }
      self.generate_or_update_settings(settings)
    end

    def dropdown_required?
      !values_list.blank?
    end


    def parsed_values_list_for_dropdown
      unless values_list.blank?
        values_list.split(";")
      end
    end



    def self.get_setting(key)
      if Gluttonberg::Setting.table_exists?
        data  = nil
        begin
          data = Rails.cache.read("setting_#{key}")
        rescue
        end
        if data.blank?
          setting = Setting.find(:first , :conditions => { :name => key })
          data = ( (!setting.blank? && !setting.value.blank?) ? setting.value : "" )
           Rails.cache.write("setting_#{key}" , (data.blank? ? "~" : data))
           data
        elsif data == "~" # empty setting
          ""
        else
          data
        end
      end
    end

    def self.update_settings(settings={})
      settings.each do |key , val |
        obj = self.first(:name=> key)
        obj.value = val
        obj.save!
      end
    end

    def update_settings_in_config
      begin
        setting = self
        Rails.cache.write("setting_#{setting.name}" , setting.value)
      rescue => e
        Rails.logger.info e
      end
    end

    def destroy_cache
      Rails.cache.write("setting_#{self.name}" , "")
    end


  end
end
