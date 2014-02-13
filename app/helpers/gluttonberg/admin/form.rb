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

      def admin_form_controls_for_approving_or_decling_objects(version, opts={})
        html = submit_tag("Approve" , :id => "publish_btn", :class => "btn btn-success publishing_btn").html_safe
        html += " ".html_safe +  link_to("Decline", admin_decline_content_path(version.class.name.gsub("::Version",""), version.id) , :id => "decline_btn", :class => "btn btn-danger ").html_safe
        content_tag(:p, html.html_safe, :class => "controls")
      end

      # new form controls based on new logic of authorization and publishing workflow
      def submit_and_publish_controls(form, object, can_publish, schedule_field=true, revisions=true, opts={})
        version_status = ''
        begin
          version_status = !object.respond_to?(:loaded_version) || object.loaded_version.blank? ? '' : object.loaded_version.version_status
        rescue
        end
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
            admin_form_controls_for_approving_or_decling_objects(object.loaded_version, opts)
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

      def version_dashboard_notifications_data
        submitted_content = []

        Gluttonberg::Content::actual_content_classes.each do |klass|
          uniq_key = klass.columns.map(&:name).include?('page_localization_id') ? :page_localization_id : :page_id
          klass::Version.where(:version_status => ['submitted_for_approval']).select(uniq_key).uniq.all.each do |submitted_version|
            object_id = (submitted_version.respond_to?(:page_localization_id) ? submitted_version.page_localization_id : submitted_version.page_id)
            object = Gluttonberg::PageLocalization.where(:id => object_id).first
            unless object.blank?
              versions = object.versions
              unless versions.blank?
                versions = versions.sort{|x, y| y.version <=> x.version}
                versions = versions.find_all{|v| v.version_status == "published" ||  v.version_status == "submitted_for_approval"}
                
                published_version = nil
                versions.each do |version|
                  published_version = version if version.version_status == "published"
                  if (published_version.blank? || published_version.version < version.version) 
                    if version.version_status == "submitted_for_approval"
                      path = edit_admin_page_page_localization_path( :page_id => object.page_id, :id => object.id) + "?version=#{version.version}"
                      submitted_content << [object.name, path, version] 
                      break
                    end
                  end
                end # versions loop
              end
            end
          end
        end # pages

        if Gluttonberg.constants.include?(:Blog) && Gluttonberg::Blog::Article
          Gluttonberg::Blog::ArticleLocalization::Version.where(:version_status => ['submitted_for_approval']).includes(:article_localization).all.each do |submitted_version|
            object = submitted_version.article_localization
            versions = object.versions
            unless versions.blank?
              versions = versions.sort{|x, y| y.version <=> x.version}
              versions = versions.find_all{|v| v.version_status == "published" ||  v.version_status == "submitted_for_approval"}
              published_version = nil
              versions.each do |version|
                published_version = version if version.version_status == "published"
                if (published_version.blank? || published_version.version < version.version) 
                  if version.version_status == "submitted_for_approval"
                    path = edit_admin_blog_article_path( :blog_id => object.article.blog_id, :localization_id => object.id, :id => object.article.id, :version => version.version)
                    submitted_content << [object.title, path, version] 
                    break
                  end
                end
              end 
            end
          end
        end # articles

        Gluttonberg::Components.nav_entries.each do |entry|
          unless entry[4].blank?
            if Kernel.const_get(entry[4]).versioned?
              association = entry[4].demodulize.underscore
              query = Kernel.const_get(entry[4])::Version.where(:version_status => ['submitted_for_approval']).includes(association)
              query.all.each do |submitted_version|
                object = submitted_version.send(association)
                versions = object.versions
                unless versions.blank?
                  versions = versions.sort{|x, y| y.version <=> x.version}
                  versions = versions.find_all{|v| v.version_status == "published" ||  v.version_status == "submitted_for_approval"}
                  published_version = nil
                  versions.each do |version|
                    published_version = version if version.version_status == "published"
                    if (published_version.blank? || published_version.version < version.version) 
                      if version.version_status == "submitted_for_approval"
                        path = "#{url_for(entry[2])}/#{object.id}/edit" + "?version=#{version.version}"
                        submitted_content << [object.title_or_name?, path, version] 
                        break
                      end
                    end
                  end 
                end
              end
            end #versioned
          end
        end # custom models

        submitted_content.uniq! unless submitted_content.blank?
        submitted_content = submitted_content.sort{|x,y| y[2].created_at <=>  x[2].created_at }
      end

      def version_dashboard_notifications
        if current_user.ability.can?(:publish, :any)
          submitted_content = version_dashboard_notifications_data

          more = (submitted_content.length > 5)
          submitted_content = submitted_content[0..4] if more
          render :partial => "/gluttonberg/admin/shared/version_dashboard_notifications", :locals => {
            :submitted_content => submitted_content,
            :more => more
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