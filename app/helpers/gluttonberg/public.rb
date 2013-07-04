# encoding: utf-8

module Gluttonberg
    # A few simple helpers to be used when rendering page templates.
    module Public
      include PageInfo
      include MetaTags
      include NavTree
      include HtmlTruncate
      include Assets

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
