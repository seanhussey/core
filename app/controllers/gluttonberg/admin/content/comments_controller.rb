# encoding: utf-8

module Gluttonberg
  module Admin
    module Content
      class CommentsController < Gluttonberg::Admin::BaseController
        include ActionView::Helpers::TextHelper
        before_filter :is_blog_enabled
        before_filter :find_blog , :except => [:all , :approved, :rejected , :pending , :spam , :moderation , :delete , :destroy , :spam_detection_for_all_pending , :block_comment_author]
        before_filter :find_article ,  :except => [:index, :all , :approved , :rejected , :pending , :spam , :moderation , :delete , :destroy , :spam_detection_for_all_pending , :block_comment_author]
        before_filter :authorize_user ,  :except => [:moderation]


        def index
          find_article([:comments])
          @comments = @article.comments.order("created_at DESC").paginate(:per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"), :page => params[:page] , :order => "created_at DESC")
        end

        def delete
          @comment = Comment.where(:id => params[:id]).first
          display_delete_confirmation(
            :title      => "Delete Comment ?",
            :url        => admin_comment_destroy_path(@comment),
            :return_url => :back,
            :warning    => ""
          )
        end

        def moderation
          authorize_user_for_moderation
          @comment = Comment.where(:id => params[:id]).first
          @comment.moderate(params[:moderation])
          Gluttonberg::Feed.log(current_user,@comment, truncate(@comment.body, :length => 100) , params[:moderation])
          redirect_to :back
        end

        def destroy
          @comment = Comment.where(:id => params[:id]).first
          if @comment.delete
            flash[:notice] = "The comment was successfully deleted."
            Gluttonberg::Feed.log(current_user,@comment, truncate(@comment.body, :length => 100) , "deleted")
            redirect_to admin_pending_comments_path()
          else
            flash[:error] = "There was an error deleting the comment."
            redirect_to admin_pending_comments_path()
          end
        end


        def pending
          @comments = Comment.all_pending.order("created_at DESC").paginate(:per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"), :page => params[:page] , :order => "created_at DESC")
          render :template => "/gluttonberg/admin/content/comments/index"
        end

        def approved
          @comments = Comment.all_approved.order("created_at DESC").paginate(:per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"), :page => params[:page] , :order => "created_at DESC")
          render :template => "/gluttonberg/admin/content/comments/index"
        end

        def rejected
          @comments = Comment.all_rejected.order("created_at DESC").paginate(:per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"), :page => params[:page] , :order => "created_at DESC")
          render :template => "/gluttonberg/admin/content/comments/index"
        end

        def spam
          @comments = Comment.all_spam.order("created_at DESC").paginate(:per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"), :page => params[:page] , :order => "created_at DESC")
          render :template => "/gluttonberg/admin/content/comments/index"
        end

        def spam_detection_for_all_pending
          Comment.spam_detection_for_all
          redirect_to admin_pending_comments_path
        end

        def block_comment_author
          @comment = Comment.where(:id => params[:id]).first

          author_string = ""
          unless @comment.author_name.blank? || @comment.author_name == "NULL" || @comment.author_name.length < 3
            author_string += @comment.author_name
          end
          unless @comment.author_email.blank? || @comment.author_email == "NULL" || @comment.author_email.length < 3
            author_string += ", " unless author_string.blank?
            author_string += @comment.author_email
          end
          unless @comment.author_website.blank? || @comment.author_website == "NULL" || @comment.author_website.length < 3
            author_string += ", " unless author_string.blank?
            author_string += @comment.author_website
          end
          unless author_string.blank?
            author_string
            gb_blacklist_settings = Gluttonberg::Setting.get_setting("comment_blacklist")
            if gb_blacklist_settings.blank?
              gb_blacklist_settings = author_string
            else
              gb_blacklist_settings = gb_blacklist_settings + ", " + author_string
            end
            Gluttonberg::Setting.update_settings("comment_blacklist" => gb_blacklist_settings)
            Comment.spam_detection_for_all
          end
          redirect_to admin_pending_comments_path
        end



        protected

          def find_blog
            @blog = Blog.where(:id => params[:blog_id]).first
            raise ActiveRecord::RecordNotFound unless @blog
          end

          def find_article(include_model=[])
            conditions = { :id => params[:article_id] }
            conditions[:user_id] = current_user.id unless current_user.super_admin?
            @article = Article.where(conditions).includes(include_model).first
            raise ActiveRecord::RecordNotFound unless @article
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Comment
          end

          def authorize_user_for_moderation
            authorize! :moderate, Gluttonberg::Comment
          end
      end
    end
  end
end
