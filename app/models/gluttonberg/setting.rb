module Gluttonberg
 class Setting  < ActiveRecord::Base
    self.table_name = "gb_settings"

    after_save :update_settings_in_config

    before_destroy :destroy_cache

    attr_accessible :name, :value, :values_list, :help, :category
    attr_accessible :row, :delete_able, :enabled, :site

    # Included mixins which are registered by host app for extending functionality
    MixinManager.load_mixins(self)

    def self.generate_or_update_settings(settings, site=nil)
      settings.each do |key , val |
        obj = self.where(:name => key).first
        if obj.blank? || obj.site != site
          obj = self.new({
            :name=> key,
            :value => val[0],
            :row => val[1],
            :delete_able => false,
            :help => val[2],
            :values_list => val[3],
            :site => site
          })
          obj.save!
        else
          obj.update_attributes({
            :name=> key,
            :row => val[1],
            :delete_able => false,
            :help => val[2],
            :site => site
          })
        end
      end
    end

    def user_friendly_name
      name.titlecase
    end

    # Generate common settings for gluttonberg
    # If its not multisite case then it only creates one set of settings
    # In case of multisite it creates one set of global settings 
    # and xx times for websited based settings
    def self.generate_common_settings
      cms_settings = {
        :number_of_revisions => ["10" , 6 , "Number of revisions to maintain for versioned contents."],
        :library_number_of_recent_assets => ["15" , 7 , "Number of recent assets in asset library."],
        :number_of_per_page_items => ["20" , 8 , "Number of per page items for any paginated content."],
        :enable_WYSIWYG => ["Yes" , 9 , "Enable WYSIWYG on textareas" , "Yes;No" ],
        :backend_logo => ["" , 10 , "Logo for backend" ] ,
        :auto_save_time => ["30" , 22 , "If editing is in progress then gluttonberg will auto save the form in XX seconds" ]
      }

      settings = {
        :video_assets => ["" , 13 , "FFMPEG settings" , "Enable;Disable"],
        :s3_key_id => ["" , 14 , "S3 Key ID"],
        :s3_access_key => ["" , 15 , "S3 Access Key"],
        :s3_server_url => ["" , 16 , "S3 Server URL"],
        :s3_bucket => ["" , 17 , "S3 Bucket Name"],
        :audio_assets => ["" , 18 , "Audio settings" , "Enable;Disable"],
        :comment_blacklist => ["" , 19 , "When a comment contains any of these words in its comment, Author Name, Author website, Author e-mail, it will be marked as spam. It will match inside words, so \"able\" will match \"comparable\". Please separate words with a comma."],
        :comment_email_as_spam => ["Yes" , 20 , "Do you want to mark those comments as spam which only contains emails and urls?" , "Yes;No" ],
        :comment_number_of_emails_allowed => ["2" , 21 , "How many email addresses should a comment include to be marked as spam?" ],
        :comment_number_of_urls_allowed => ["2" , 21 , "How many URLs should a comment include to be marked as spam?" ]
      }

      sitewise_settings = {
        :title => [ "" , 0, "Website Title"],
        :keywords => ["" , 1, "Please separate keywords with a comma."],
        :description => ["" ,2 , "The Description will appear in search engine's result list."],
        :fb_icon => ["" , 3 , "Facebook Icon for the website"],
        :google_analytics => ["", 4, "Google Analytics ID"],
        :from_email => ["" , 12 , "This email address is used for 'from' email address for all emails sent through system."],
        :restrict_site_access => ["" , 11 , "If this setting is provided then user needs to enter password to access public site."],
        :comment_notification => ["No" , 5 , "Enable comment notification" , "Yes;No" ]
      }

      self.generate_or_update_settings(cms_settings)
      self.generate_or_update_settings(settings)
      if Rails.configuration.multisite == false
        self.generate_or_update_settings(sitewise_settings)
      else
        Rails.configuration.multisite.each do |key, val|
          self.generate_or_update_settings(sitewise_settings, key)
        end
      end

      version = Version.new
      version.version_number = VERSION
      version.save

    end

    def self.has_deletable_settings?
      self.where(:delete_able => true).count > 0
    end

    def dropdown_required?
      !values_list.blank?
    end

    def parsed_values_list_for_dropdown
      unless values_list.blank?
        values_list.split(";")
      end
    end

    def self.get_setting(key, site='')
      if Gluttonberg::Setting.table_exists?
        cache_key = (site.blank? ? "setting_#{key}" : "setting_#{key}_#{site}")
        data  = nil
        begin
          data = Rails.cache.read(cache_key)
        rescue
        end
        if data.blank?
          setting = Setting.where(:name => key)
          setting = setting.where(:site => site) unless site.blank?
          setting = setting.first
          data = ( (!setting.blank? && !setting.value.blank?) ? setting.value : "" )
           Rails.cache.write(cache_key , (data.blank? ? "~" : data))
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
        obj = self.where(:name=> key).first
        unless obj.blank?
          obj.value = val
          obj.save!
        end
      end
    end

    def update_settings_in_config
      begin
        cache_key = (self.site.blank? ? "setting_#{self.name}" : "setting_#{self.name}_#{self.site}")
        Rails.cache.write(cache_key , self.value)
      rescue => e
        Rails.logger.info e
      end
    end

    def destroy_cache
      cache_key = (self.site.blank? ? "setting_#{self.name}" : "setting_#{self.name}_#{self.site}")
      Rails.cache.write(cache_key , "")
    end
  end
end
