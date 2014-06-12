module Gluttonberg
  module Admin
    class MainController < Gluttonberg::Admin::BaseController
      unloadable
      before_filter :authorizer_for_publish , :only => [:waiting_for_approval , :decline_content]

      # Dashboad
      def index
        @categories_count = ActsAsTaggableOn::Tag.find_by_sql(%{
          select count(DISTINCT tags.id) as category_count
          from tags inner join taggings on tags.id = taggings.tag_id
          where context = 'article_category'
        }).first.category_count
        @tags_counts =  ActsAsTaggableOn::Tag.count - @categories_count.to_i

        if Gluttonberg.constants.include?(:Blog)
          @blog = Gluttonberg::Blog::Weblog.first
        end

        if Gluttonberg.constants.include?(:Blog)
          @comments = Gluttonberg::Blog::Comment.all_pending.where({:commentable_type => "Gluttonberg::Article" , :moderation_required => true }).order("created_at DESC").limit(5)
          @article = Gluttonberg::Blog::Article.new
          @blogs = Gluttonberg::Blog::Weblog.all
          @authors = User.all
        end
      end

      def show
      end

      # list of content which is waiting for approval
      def waiting_for_approval
      end

      # decline content which is waiting for approval
      def decline_content
        version, status = find_version_and_update_status
        if status
          unless version.user.blank?
            notify_user(version)
          end
          flash[:notice] = "You have declined this version, the contributor has been notified."
        else
          flash[:error] = "The version was failed to decline."
        end
        redirect_to :back
      end

      private
        def authorizer_for_publish
          authorize! :publish, :any
        end

        def find_version_and_update_status
          make_sure_localized_classes_are_loaded
          status = false
          version = params[:object_class].constantize::Version.where(:id => params[:version_id]).first
          unless version.blank?
            if version.version_status == 'submitted_for_approval'
              version.version_status = 'declined'
              status = version.save
            end
          end
          return version, status
        end

        def notify_user(version)
          title = if Gluttonberg::Content::actual_content_classes.map{|obj| obj.name}.include?(params[:object_class])
            find_page_object_and_title(version)
          elsif params[:object_class] == "Gluttonberg::Blog::ArticleLocalization"
            find_article_and_title(version)
          else
            find_custom_model_and_title(version) 
          end
          Notifier.version_declined(current_user, version, request.referer, title).deliver 
        end

        def find_page_object_and_title(version)
          object_id = (version.respond_to?(:page_localization_id) ? version.page_localization_id : version.page_id)
          object = Gluttonberg::PageLocalization.where(:id => object_id).first
          object.name unless object.blank?
        end

        def find_article_and_title(version)
          object = version.article_localization
          object.title unless object.blank?
        end

        def find_custom_model_and_title(version)
          object = version.send(params[:object_class].demodulize.underscore.to_sym)
          object.title_or_name? unless object.blank?
        end

        def make_sure_localized_classes_are_loaded
          if params[:object_class][-12..-1] == "Localization"
            params[:object_class][0..-13].constantize
          end
        end

    end
  end
end
