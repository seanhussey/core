module Gluttonberg
  module Admin
    class MainController < Gluttonberg::Admin::BaseController
      unloadable
      before_filter :authorizer_for_publish , :only => [:waiting_for_approval , :decline_content]

      def index
        @categories_count = ActsAsTaggableOn::Tag.find_by_sql(%{
          select count(DISTINCT tags.id) as category_count
          from tags inner join taggings on tags.id = taggings.tag_id
          where context = 'article_category'
        }).first.category_count
        @tags_counts =  ActsAsTaggableOn::Tag.count - @categories_count.to_i

        if Blog.table_exists?
          @blog = Blog.first
        end

        if Comment.table_exists?
          @comments = Comment.all_pending.where({:commentable_type => "Gluttonberg::Article" , :moderation_required => true }).order("created_at DESC").limit(5)
          @article = Article.new
          @article_localization = ArticleLocalization.new(:article => @article , :locale_id => Locale.first_default.id)
          @blogs = Gluttonberg::Blog.all
          @authors = User.all
        end
      end

      def show
      end

      def waiting_for_approval
      end

      def decline_content
        status = false
        version = params[:object_class].constantize::Version.where(:id => params[:version_id]).first
        unless version.blank?
          if version.version_status == 'submitted_for_approval'
            version.version_status = 'declined'
            status = version.save
          end
        end
        if status
          unless version.user.blank?
            title = if Gluttonberg::Content::actual_content_classes.map{|obj| obj.name}.include?(params[:object_class])
              object_id = (version.respond_to?(:page_localization_id) ? version.page_localization_id : version.page_id)
              object = Gluttonberg::PageLocalization.where(:id => object_id).first
              object.name unless object.blank?
            elsif params[:object_class] == "Gluttonberg::ArticleLocalization"
              object = version.article_localization
              object.title unless object.blank?
            else
              object = version.send(params[:object_class].demodulize.underscore.to_sym)
              object.title_or_name? unless object.blank?
            end
            Notifier.version_declined(current_user, version, request.referer, title).deliver 
          end
          flash[:notice] = "The version was successfully declined."
        else
          flash[:notice] = "The version was failed to decline."
        end
        redirect_to :back
      end

      private
        def authorizer_for_publish
          authorize! :publish, :any
        end

    end
  end
end
