# encoding: utf-8

module Gluttonberg
  module Admin
    module Content
      class CommentsController < Gluttonberg::Admin::BaseController
        include ActionView::Helpers::TextHelper

        before_filter :find_blog , :except => [:all , :approved, :rejected , :pending , :spam , :moderation , :delete , :destroy]
        before_filter :find_article ,  :except => [:index, :all , :approved , :rejected , :pending , :spam , :moderation , :delete , :destroy]
        before_filter :authorize_user ,  :except => [:moderation]


        def index
          find_article([:comments])
          @comments = @article.comments.order("created_at DESC").paginate(:per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"), :page => params[:page] , :order => "created_at DESC")
        end

        def delete
          @comment = Comment.find(params[:id])
          display_delete_confirmation(
            :title      => "Delete Comment ?",
            :url        => admin_comment_destroy_path(@comment),
            :return_url => :back,
            :warning    => ""
          )
        end

        def moderation
          authorize_user_for_moderation
          @comment = Comment.find(params[:id])
          @comment.moderate(params[:moderation])
          Gluttonberg::Feed.log(current_user,@comment, truncate(@comment.body, :length => 100) , params[:moderation])
          redirect_to :back
        end

        def destroy
          @comment = Comment.find(params[:id])
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



        protected

          def find_blog
            @blog = Blog.find(params[:blog_id])
            raise ActiveRecord::RecordNotFound unless @blog
          end

          def find_article(include_model=[])
            conditions = { :id => params[:article_id] }
            conditions[:user_id] = current_user.id unless current_user.super_admin?
            @article = Article.find(:first , :conditions => conditions , :include => include_model )
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
