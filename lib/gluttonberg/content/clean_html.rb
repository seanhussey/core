module Gluttonberg
  module Content
    # This mixin provides helper methods which are used to clean html
    module CleanHtml
      extend ActiveSupport::Concern
      def self.setup
        ::ActiveRecord::Base.send :include, Gluttonberg::Content::CleanHtml
      end

      module ClassMethods
        def clean_html(cols)
          class_eval <<-EOV
            include InstanceMethods
            before_validation :clean_all_html_content
            cattr_accessor :html_columns_list
            self.html_columns_list = cols

          EOV
        end

        def clean_tags(str)
          if !str.blank? && str.instance_of?(String)
            str = self.removeStyle(str)
            str = self.removeMetaTag(str)
            str = removeEmptyTag(str)
            str = removeDuplicatedBreaks(str)
          end
          str
        end

        def removeEmptyTag(str)
          removeList = [/<blockquote>[\s]*<\/blockquote>/, /<p>[\s]*<\/p>/,/<div>[\s]*<\/div>/,/<span>[\s]*<\/span>/, /<h1>[\s]*<\/h1>/, /<h2>[\s]*<\/h2>/, /<h3>[\s]*<\/h3>/, /<h4>[\s]*<\/h4>/, /<h5>[\s]*<\/h5>/, /<h6>[\s]*<\/h6>/]
          removeList.each do |r|
            str = str.gsub(r,"")
          end

          str
        end

        def removeDuplicatedBreaks(str)
          str.gsub(/((<br[\s]*\/>[\s]*)|(<br[\s]*>[\s]*))+/,'<br/>')
        end

        def removeStyle(str)
          removeList = [/style=\"[\sA-Za-z0-9.,-;:]*\"/]
          removeList.each do |r|
            str = str.gsub(r,"")
          end

          str
        end

        def removeMetaTag(str)
           removeList = [ "<meta charset=\"utf-8\">", "</meta>" ]
           removeList.each do |r|
            str = str.gsub(r,"")
          end

          str
        end
      end

      def clean_all_html_content
        unless self.class.html_columns_list.blank?
          self.class.html_columns_list.each do |field|
            write_attribute(field , self.class.clean_tags(read_attribute(field)) )
          end
        end
      end

    end
  end
end