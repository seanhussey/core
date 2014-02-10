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

      def contributor_form_controls(published, opts={})
        html = submit_tag("Save draft" , :id => "#{published ? 'revision_btn' : 'draft_btn'}", :class => "btn publishing_btn").html_safe
        html += " ".html_safe +  submit_tag("Submit for approval" , :id => "approval_btn", :class => "btn btn-success publishing_btn").html_safe
        content_tag(:p, html.html_safe, :class => "controls")
      end

      def admin_form_controls_for_draft_objects(opts={})
        html = submit_tag("Save draft" , :id => "draft_btn", :class => "btn publishing_btn").html_safe
        html += " ".html_safe +  submit_tag("Publish" , :id => "publish_btn", :class => "btn btn-success publishing_btn").html_safe
        content_tag(:p, html.html_safe, :class => "controls")
      end

      def admin_form_controls_for_published_objects(revisions=true, opts={})
        html =  ""
        html += submit_tag("Save revision" , :id => "revision_btn", :class => "btn publishing_btn").html_safe if revisions == true
        html += " ".html_safe +  submit_tag("Update" , :id => "update_btn", :class => "btn btn-success publishing_btn").html_safe
        html += " ".html_safe +  submit_tag("Unpublish" , :id => "unpublish_btn", :class => "btn btn-danger publishing_btn").html_safe
        content_tag(:p, html.html_safe, :class => "controls")
      end

      def admin_form_controls_for_approving_or_decling_objects(opts={})
        html = submit_tag("Approve" , :id => "publish_btn", :class => "btn btn-success publishing_btn").html_safe
        html += " ".html_safe +  submit_tag("Decline" , :id => "decline_btn", :class => "btn btn-danger publishing_btn").html_safe
        content_tag(:p, html.html_safe, :class => "controls")
      end

      # new form controls based on new logic of authorization and publishing workflow
      def submit_and_publish_controls(form, object, can_publish, schedule_field=true, revisions=true, opts={})
        version_status = object.loaded_version.blank? ? '' : object.loaded_version.version_status
        html = content_tag("legend", "Publish").html_safe
        if object.published?
          html += content_tag(:p, "<span class='date'>Published on #{object.published_at.strftime("%d/%m/%Y")}</span>".html_safe)
        else
          html += form.publishing_schedule(schedule_field)
        end
        html += form.hidden_field(:state, :class => "_publish_state") 
        html += form.hidden_field(:_publish_status, :class => "_publish_status") 
        html += if can_publish
          if version_status == 'submitted_for_approval'
            admin_form_controls_for_approving_or_decling_objects(opts)
          elsif object.published?
            admin_form_controls_for_published_objects(revisions, opts)
          else
            admin_form_controls_for_draft_objects(opts)
          end
        else
          contributor_form_controls(object.published?, opts)
        end
        html.html_safe
      end

      def version_listing(versions , selected_version_num)
        unless versions.blank?
          versions = versions.order("version DESC")
          selected = versions.last.version
          selected_version = versions.first
          versions.each do |version|
            if version.version.to_i == selected_version_num.to_i
              selected = version.version
              selected_version = version
            end
          end
          render :partial => "/gluttonberg/admin/shared/version_listing", :locals => {
            :versions => versions,
            :selected_version_num => selected_version_num,
            :selected => selected,
            :selected_version => selected_version
          }
        end
      end #version_listing

      def version_alerts(versions , selected_version_num, can_publish)
        unless versions.blank?
          versions = versions.order("version DESC")
          your_revisions = []
          submitted_for_approval = []
          published_version = nil
          versions.each do |version|
            published_version = version if version.version_status == "published"
            if (published_version.blank? || published_version.version < version.version) && version.version != selected_version_num.to_i
              submitted_for_approval << version if version.version_status == "submitted_for_approval"
              your_revisions << version if version.version_status == "revision" && version.version_user_id == current_user.id
            end
          end
          render :partial => "/gluttonberg/admin/shared/version_alerts", :locals => {
            :submitted_for_approval => submitted_for_approval,
            :your_revisions => your_revisions,
            :can_publish => can_publish
          }
        end
      end #version_alerts


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