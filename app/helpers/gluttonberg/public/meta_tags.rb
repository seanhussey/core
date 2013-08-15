# encoding: utf-8

module Gluttonberg
  module Public
    module MetaTags
      def keywords_meta_tag
        _meta_tag("keywords", "keywords")
      end

      def description_meta_tag
        _meta_tag("description", "description")
      end

      private
        def _meta_tag(setting_name, tag_name)
          value = Gluttonberg::Setting.get_setting(setting_name)
          unless value.blank?
            tag("meta",{:content =>  value, :name => tag_name } ) 
          else
            nil
          end
        end
    end
  end
end