# encoding: utf-8

module Gluttonberg
    # A few simple helpers to be used when rendering page templates.
    module Public
      include PageInfo
      include MetaTags
      include NavTree

      # Returns the code for google analytics
      def google_analytics_js_tag
        code = Gluttonberg::Setting.get_setting("google_analytics")
        unless code.blank?
          javascript_tag do
            %{
              var _gaq = _gaq || [];
              _gaq.push(['_setAccount', '#{code}']);
              _gaq.push(['_trackPageview']);
              (function() {
                var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
                ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
                var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
              })();
            }.html_safe
          end
        end
      end

      def render_match_partial(result)
        begin
          klass = result.class.name.demodulize.underscore
          render :partial => "search/#{klass}", :locals => { :result => result }
        rescue ActionView::MissingTemplate => e
          "Missing search template for model #{klass}. Create a search/_#{klass}.html.erb partial in the correct plugin and try again."
        rescue RuntimeError => e
          "Unable to find the class name of the following match #{debug result}"
        end
      end

      def link_to_inappropriate(obj)
        if current_user and current_user.flagged?(obj)
          content_tag(:p, "You have already flagged this item.")
        else
          link_to "Inappropriate" , mark_as_flag_path(obj.class.name , obj.id)
        end
      end


      # Does NOT behave identical to current Rails truncate method
      # you must pass options as a hash not just values
      # Sample usage: <%= html_truncate(category.description, :length =>
      # 120, :omission => "(continued...)" ) -%>...

      def html_truncate(html, truncate_length, options={})
        text, result = [], []
        previous_tags = []
        # get all text (including punctuation) and tags and stick them in a hash
        html.scan(/<\/?[^>]*>|[A-Za-z0-9.,\/&#;\!\+\(\)\-"'?]+/).each { |t| text << t }
        #puts text
        text.each do |str|
          if truncate_length > 0
            if str =~ /<\/?[^>]*>/
              if str[0..1] != "</"
                previous_tags.push(str)
              else
                previous_tags.pop()
              end
              result << str
            else
              result << str
              truncate_length -= str.length
            end
          else
            # now stick the next tag with that matches the previous
            # open tag on the end of the result
            while previous_tags.length > 0
              previous_tag = previous_tags.pop()
              unless previous_tag.start_with?("<br") || previous_tag.start_with?("<hr") || previous_tag.start_with?("<input")

                tokens = previous_tag.split(" ")
                if tokens.length == 1
                  closing_tag = tokens.first.insert(1 , '/')
                else
                  closing_tag = "#{tokens.first.insert(1 , '/')}>"
                end
                result << closing_tag
              end
            end
          end
        end

        return result.join(" ") + options[:omission].to_s
      end


      def db_stylesheet_link_tag
        if Rails.configuration.cms_based_public_css == true
           html = ""
           Gluttonberg::Stylesheet.all.each do |stylesheet|
             html << "\n"
             unless stylesheet.css_prefix.blank?
               html << stylesheet.css_prefix
               html << "\n"
             end
             html << stylesheet_link_tag( stylesheets_path(stylesheet.slug) +".css?#{stylesheet.version}" )
             unless stylesheet.css_postfix.blank?
               html << "\n"
               html << stylesheet.css_postfix
             end
           end
           html << "\n"
           html.html_safe
         end
       end


      def clean_public_query(string)
        unless string.blank?
          string = string.gsub("'", "\\\\'")
          string = string.gsub("\"", "\\\"")
          string = string.gsub(/\${2,}/, "$")
        else
          string
        end
      end

      def clean_public_query_for_sphinx(string)
        unless string.blank?
          string = clean_public_query(string)
          string = string.gsub("$", "")
          string = string.gsub(/[\!\*'"″′‟‘’‛„‚”“”˝\(\)\;\:\.\@\&\=\+\-\$\,\/?\%\#\[\]]/,'')
        else
          string
        end
      end

    end # Public
end # Gluttonberg
