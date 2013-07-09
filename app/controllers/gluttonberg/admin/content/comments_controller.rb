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
          @comments = ordering_and_pagination(Comment.all_pending)
          render_comments_list
        end

        def approved
          @comments = ordering_and_pagination(Comment.all_approved)
          render_comments_list
        end

        def rejected
          @comments = ordering_and_pagination(Comment.all_rejected)
          render_comments_list
        end

        def spam
          @comments = ordering_and_pagination(Comment.all_spam)
          render_comments_list
        end

        def spam_detection_for_all_pending
          Comment.spam_detection_for_all
          redirect_to admin_pending_comments_path
        end

        def block_comment_author
          @comment = Comment.where(:id => params[:id]).first
          @comment.black_list_author
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

          def ordering_and_pagination(comments)
            comments.order("created_at DESC").paginate({
              :per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"),
              :page => params[:page]
            })
          end

          def render_comments_list
            render :template => "/gluttonberg/admin/content/comments/index"
          end
      end
    end
  end
end
