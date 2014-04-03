module Gluttonberg
  module Admin
    module Versioning
      # it renders a warning box with message and buttons for restoring/cancel  (warning about un saved version)
      # if there is any auto save version exists.
      def auto_save_version(object)
        auto_save = AutoSave.where(:auto_save_able_id => object.id, :auto_save_able_type => object.class.name).first
        if !auto_save.blank? && auto_save.updated_at > object.updated_at
          render :partial => "/gluttonberg/admin/shared/auto_save_version" , :locals => {:object => object} , :formats => [:html]
        end
      end

      # It renders warning for if user is viewing older revision of and object
      def previous_version_warning(versions , selected_version_num)
        if !versions.blank? && !selected_version_num.blank?
          versions = versions.sort{|x,y| y.version <=> x.version}
          if selected_version_num.to_i < versions.first.version
            render :partial => "/gluttonberg/admin/shared/previous_version_warning" , :locals => {:selected_version_num => selected_version_num} , :formats => [:html]
          end
        end
      end

      # Enable auto save on a form
      def auto_save(object)
        "#{auto_save_js_tag(object)} \n #{auto_save_version(object)}".html_safe
      end

      def auto_save_js_tag(object)
        delay = Gluttonberg::Setting.get_setting('auto_save_time')
        unless delay.blank?
          javascript_tag do
            %{
              $(document).ready(function(){
                AutoSave.save("/admin/autosave/#{object.class.name}/#{object.id}", #{delay});
              });
            }.html_safe
          end
        end
      end

      # It shows 3 kind of warnings depending on case
      # Reviewing Version xx: Submitted for approval
      # Version xx: Waiting for approval
      # Version xx: Unpublished revision 
      def version_alerts(versions , selected_version_num, can_publish)
        unless versions.blank?
          versions = versions.order("version DESC")
          your_revisions = []
          submitted_for_approval = []
          published_version = nil
          viewing_waiting_for_approval = nil
          versions.each do |version|
            published_version = version if version.version_status == "published"
            if (published_version.blank? || published_version.version < version.version)
              if version.version != selected_version_num.to_i
                submitted_for_approval << version if version.version_status == "submitted_for_approval"
                your_revisions << version if version.version_status == "revision" && version.version_user_id == current_user.id
              else
                viewing_waiting_for_approval = version if version.version_status == "submitted_for_approval"
              end
            end
          end
          render :partial => "/gluttonberg/admin/shared/version_alerts", :locals => {
            :submitted_for_approval => submitted_for_approval,
            :your_revisions => your_revisions,
            :can_publish => can_publish,
            :viewing_waiting_for_approval => viewing_waiting_for_approval
          }
        end
      end #version_alerts

      def version_dashboard_notifications_data
        submitted_content = []

        _page_version_dashboard_notifications_data(submitted_content)
        _blog_version_dashboard_notifications_data(submitted_content)
        _custom_models_version_dashboard_notifications_data(submitted_content)

        submitted_content.uniq! unless submitted_content.blank?
        submitted_content = submitted_content.sort{|x,y| y[2].created_at <=>  x[2].created_at }
      end

      # this renders recently submitted contents(max 5 items). Its used on dashboard
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

      private

        def _page_version_dashboard_notifications_data(submitted_content)
          Gluttonberg::Content::actual_content_classes.each do |klass|
            uniq_key = klass.columns.map(&:name).include?('page_localization_id') ? :page_localization_id : :page_id
            klass::Version.where(:version_status => ['submitted_for_approval']).select(uniq_key).uniq.all.each do |submitted_version|
              object_id = (submitted_version.respond_to?(:page_localization_id) ? submitted_version.page_localization_id : submitted_version.page_id)
              object = Gluttonberg::PageLocalization.where(:id => object_id).first
              unless object.blank?
                versions = object.versions
                unless versions.blank?
                  versions = _find_sorted_submitted_or_published_versions(versions)
                  
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
        end

        def _blog_version_dashboard_notifications_data(submitted_content)
          if Gluttonberg.constants.include?(:Blog) && Gluttonberg::Blog::Article
            Gluttonberg::Blog::ArticleLocalization::Version.where(:version_status => ['submitted_for_approval']).includes(:article_localization).all.each do |submitted_version|
              object = submitted_version.article_localization
              versions = object.versions
              unless versions.blank?
                versions = _find_sorted_submitted_or_published_versions(versions)
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
        end

        def _custom_models_version_dashboard_notifications_data(submitted_content)
          Gluttonberg::Components.nav_entries.each do |entry|
            unless entry[4].blank?
              _custom_model_version_dashboard_notifications_data(entry, submitted_content)
            end
          end # custom models
        end

        def _custom_model_version_dashboard_notifications_data(entry, submitted_content)
          is_localized =  entry[4].constantize.respond_to?(:localized?) && entry[4].constantize.localized?
          model_name = is_localized ? "#{entry[4]}Localization" : entry[4]
          if model_name.constantize.versioned?
            association = model_name.demodulize.underscore
            query = model_name.constantize::Version.where(:version_status => ['submitted_for_approval']).includes(association)
            query.all.each do |submitted_version|
              _prepare_message_for_a_submission_of_custom_model(entry, is_localized, model_name, association, submitted_version, submitted_content)
            end
          end #versioned
        end

        def _prepare_message_for_a_submission_of_custom_model(entry, is_localized, model_name, association, submitted_version, submitted_content)
          object = submitted_version.send(association)
          versions = object.versions
          unless versions.blank?
            versions = _find_sorted_submitted_or_published_versions(versions)
            published_version = nil
            versions.each do |version|
              published_version = version if version.version_status == "published"
              if (published_version.blank? || published_version.version < version.version) 
                if version.version_status == "submitted_for_approval"
                  path = "#{url_for(entry[2])}/#{object.id}/edit" + "?version=#{version.version}#{is_localized ? "&locale_id=#{object.locale_id}" : ''}"
                  submitted_content << [object.title_or_name?, path, version] 
                  break
                end
              end
            end 
          end
        end

        def _find_sorted_submitted_or_published_versions(versions)
          versions = versions.sort{|x, y| y.version <=> x.version}
          versions = versions.find_all{|v| v.version_status == "published" ||  v.version_status == "submitted_for_approval"}
        end

    end #versioning
  end
end