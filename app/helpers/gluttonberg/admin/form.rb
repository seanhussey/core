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

      def contributor_form_controls(cancel_url , opts={})
        html = submit_tag("Save draft" , :id => opts[:draft_id], :class => "btn ").html_safe
        html += " ".html_safe +  submit_tag("Submit for approval" , :id => opts[:approval_id], :class => "btn btn-success").html_safe
        html += link_to(" Cancel", cancel_url).html_safe
        content_tag(:p, html.html_safe, :class => "controls")
      end

      def admin_form_controls_for_draft_objects(cancel_url , opts={})
        html = submit_tag("Save draft" , :id => opts[:draft_id], :class => "btn ").html_safe
        html += " ".html_safe +  submit_tag("Publish" , :id => opts[:publish_id], :class => "btn btn-success").html_safe
        html += link_to(" Cancel", cancel_url).html_safe
        content_tag(:p, html.html_safe, :class => "controls")
      end

      def admin_form_controls_for_published_objects(cancel_url , opts={})
        html = submit_tag("Save revision" , :id => opts[:revision_id], :class => "btn").html_safe
        html += " ".html_safe +  submit_tag("Update" , :id => opts[:update_id], :class => "btn btn-success").html_safe
        html += " ".html_safe +  submit_tag("Unpublish" , :id => opts[:unpublish_id], :class => "btn btn-danger").html_safe
        html += link_to(" Cancel", cancel_url).html_safe
        content_tag(:p, html.html_safe, :class => "controls")
      end

      # new form controls based on new logic of authorization and publishing workflow
      def submit_and_publish_controls(form, object, cancel_url, can_publish, schedule_field=true, opts={})
        html = content_tag("legend", "Publish").html_safe
        html += form.publishing_schedule if schedule_field

        html += if can_publish
          if object.published?
            admin_form_controls_for_published_objects(cancel_url)
          else
            admin_form_controls_for_draft_objects(cancel_url)
          end
        else
          contributor_form_controls(cancel_url , opts)
        end
        html.html_safe
      end

      def version_listing(versions , selected_version_num)
        unless versions.blank?
          selected = versions.last.version
          selected_version = versions.first
          collection = []
          versions.each do |version|
            link = version.version
            snippet = version.updated_at.blank? ? "" : "Version #{version.version} - #{version.updated_at.to_s(:long)}  " 
            if version.version.to_i == selected_version_num.to_i
              selected = link
              selected_version = version
            end
            collection << [snippet , link]
          end
          render :partial => "/gluttonberg/admin/shared/version_listing", :locals => {
            :versions => versions,
            :selected_version_num => selected_version_num,
            :collection => collection,
            :selected => selected,
            :selected_version => selected_version
          }
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

    end #Form
  end
end