# encoding: utf-8

module Gluttonberg
  module Admin
    module Form
      def honeypot_field_tag
        html = label_tag(Rails.configuration.honeypot_field_name , Rails.configuration.honeypot_field_name.humanize )
        html << text_field_tag( Rails.configuration.honeypot_field_name )
        content_tag :div , html , :class => Rails.configuration.honeypot_field_name , :style => "display:none"
      end

      # Controls for standard forms. Writes out a save button and a cancel link
      def form_controls(return_url , opts={})
        content = "#{submit_tag("Save" , :id => opts[:submit_id], :class => "btn btn-success").html_safe} #{link_to("Cancel".html_safe, return_url, :class => "btn")}"
        content_tag(:p, content.html_safe, :class => "controls")
      end

      # Controls for publishable forms. Writes out a draft ,  publish/unpublish button and a cancel link
      def publishable_form_controls(return_url , object_name , is_published )
        content = hidden_field(:published , :value => false)
        content += "#{link_to("<strong>Cancel</strong>", return_url)}"
        content += " or #{submit_tag("draft")}"
        content += " or #{submit_tag("publish" , :onclick => "publish('#{object_name}_published')" )}"
        content_tag(:p, content, :class => "controls")
      end

      def publisable_dropdown(form ,object)
        val = object.state
        val = "ready" if val.blank? || val == "not_ready"
        @@workflow_states = [  [ 'Draft' , 'ready' ] , ['Published' , "published" ] , [ "Archived" , 'archived' ]  ]
        form.select( :state, options_for_select(@@workflow_states , val)   )
      end

      # shows publish message if object's currect version is published
      def publish_message(object , versions)
        content = msg = ""

        if versions.length > 1
          msg = content_tag(:a,  "Click here to see other versions" , :onclick => "$('#select-version').toggle();" , :href => "javascript:;"  , :title => "Click here to see other versions").html_safe
          msg = content_tag(:span , msg , :class => "view-versions").html_safe
        end

        content = content_tag(:div , "Updated on #{object.updated_at.to_s(:long)}    #{msg}".html_safe , :class => "unpublish_message") unless object.updated_at.blank?
        content.html_safe
      end

      def version_listing(versions , selected_version_num)
        unless versions.blank?
          output = "<div class='historycontrols'>"
          selected = versions.last.version
          selected_version = versions.last
          collection = []
          versions.each do |version|
            link = version.version
            snippet = "Version #{version.version} - #{version.updated_at.to_s(:long)}  " unless version.updated_at.blank?
            if version.version.to_i == selected_version_num.to_i
              selected = link
              selected_version = version
            end
            collection << [snippet , link]
          end

          # Output the form for picking the version
          versions_html = "<ul class='dropdown-menu'>"
          collection.each do |c|
            versions_html << content_tag(:li , link_to(c[0] , "?version=#{c[1]}") , :class => "#{c[1].to_s == selected.to_s ? 'active' : '' }" )
          end
          versions_html << "</ul>"

          current_version = '<a class="btn dropdown-toggle" data-toggle="dropdown" href="#">'
          current_version += "Editing Version #{selected_version.version} "
          current_version += '<span class="caret"></span>'
          current_version += '</a>'

          combined_versions = current_version
          combined_versions += versions_html

          output << content_tag(:div , combined_versions.html_safe, :class => "btn-group" )

          output += "</div>"
          output += "<div class='clear'></div>"
          output += "<br />"
          output += "<br />"
          output.html_safe
        end
      end #version_listing

      # Creates an editable span for the given property of the given object.
      #
      # === Options
      #
      # [:method]
      #   Specify the HTTP method to use: <tt>'PUT'</tt> or <tt>'POST'</tt>.
      # [:name]
      #   The <tt>name</tt> attribute to be used when the form is posted.
      # [:update_url]
      #   The URL to submit the form to.  Defaults to <tt>url_for(object)</tt>.
      def gb_editable_field(object, property, options={})

        name = "#{object.class.to_s.underscore}[#{property}]"
        value = object.send property
        update_url = options.delete(:update_url) || url_for(object)
        args = {:method => 'PUT', :name => name}.merge(options)
        %{
          <span class="editable" data-id="#{object.id}" data-name="#{name}">#{value}</span>
          <script type="text/javascript">
            (function( $ ){
              $(function(){
                var args = {data: function(value, settings) {
                  // Unescape HTML
                  var retval = value
                    .replace(/&amp;/gi, '&')
                    .replace(/&gt;/gi, '>')
                    .replace(/&lt;/gi, '<')
                    .replace(/&quot;/gi, "\\\"");
                  return retval;
                },
                   type      : 'text',
                   height : '20px',
                   cancel    : 'Cancel',
                   submit    : 'OK',
                   indicator : '#{image_tag('/assets/gb_spinner.gif')}'
                };
                $.extend(args, #{args.to_json});
                $(".editable[data-id='#{object.id}'][data-name='#{name}']").editable("#{update_url}", args);
              });
            })( jQuery );
          </script>
        }.html_safe
      end

    end
  end
end