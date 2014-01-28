# encoding: utf-8

module Gluttonberg
  module Admin
    module Content
      class ArticlesController < Gluttonberg::Admin::BaseController
        before_filter :is_blog_enabled
        before_filter :find_blog , :except => [:create]
        before_filter :find_article, :only => [:show, :edit, :update, :delete, :destroy , :duplicate]
        before_filter :authorize_user , :except => [:destroy , :delete]
        before_filter :authorize_user_for_destroy , :only => [:destroy , :delete]
        before_filter :authorize_blog_for_current_user
        record_history :@article , :title
        before_filter :all_articles, :only => [:index, :export]

        def index
          @articles = @articles.paginate({
            :per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"), 
            :page => params[:page]
          })
        end

        def show
          @comment = Comment.new
        end

        def new
          @article = Article.new
          @article_localization = ArticleLocalization.new(:article => @article , :locale_id => Locale.first_default.id)
          @authors = User.all
        end

        def create
          params[:gluttonberg_article_localization][:article][:name] = params[:gluttonberg_article_localization][:title]
          article_attributes = params["gluttonberg_article_localization"].delete(:article)
          @article = Article.new(article_attributes)
          if @article.save
            @article.create_localizations(params["gluttonberg_article_localization"])
            flash[:notice] = "The article was successfully created."
            redirect_to edit_admin_blog_article_path(@article.blog, @article)
          else
            render :edit
          end
        end

        def edit
          @authors = User.all
          unless params[:version].blank?
            @version = params[:version]
            @article.revert_to(@version)
          end
        end

        def update
          article_attributes = params["gluttonberg_article_localization"].delete(:article)
          if @article_localization.update_attributes(params[:gluttonberg_article_localization])
            article = @article_localization.article
            article.update_attributes(article_attributes)

            _log_article_changes

            flash[:notice] = "The article was successfully updated."
            redirect_to edit_admin_blog_article_path(@article.blog, @article)
          else
            flash[:error] = "Sorry, The article could not be updated."
            render :edit
          end
        end

        def delete
          display_delete_confirmation(
            :title      => "Delete Article '#{@article.title}'?",
            :url        => admin_blog_article_path(@blog, @article),
            :return_url => admin_blog_articles_path(@blog),
            :warning    => ""
          )
        end

        def destroy
          generic_destroy(@article, {
            :name => "article",
            :success_path => admin_blog_articles_path(@blog),
            :failure_path => admin_blog_articles_path(@blog)
          })
        end

        def duplicate
          @duplicated_article = @article.duplicate
          @duplicated_article.user_id = current_user.id
          if @duplicated_article
            flash[:notice] = "The article was successfully duplicated."
            redirect_to edit_admin_blog_article_path(@blog, @duplicated_article)
          else
            flash[:error] = "There was an error duplicating the article."
            redirect_to admin_blog_articles_path(@blog)
          end
        end

        def import
          unless params[:csv].blank?
            @feedback = Article.importCSV(params[:csv].tempfile.path, {
              :additional_attributes => {
                :blog_id => @blog.id,
                :author_id => current_user.id,
                :user_id => current_user.id
              }
            })
            if @feedback == true
              flash[:notice] = "All contacts were successfully imported."
              redirect_to admin_blog_articles_path(@blog)
            end
          end
        end

        def export
          csv_data = Article.exportCSV(@articles.all)
          unless csv_data.blank?
            send_data csv_data, :type => 'text/csv; charset=utf-8' , :disposition => 'attachment' , :filename => "#{@blog.name} posts at #{Time.now.strftime('%Y-%m-%d')}.csv"
          end
        end

        protected

          def find_blog
            @blog = Blog.where(:id => params[:blog_id]).first
          end

          def find_article
            if params[:localization_id].blank?
              conditions = { :article_id => params[:id] , :locale_id => Locale.first_default.id}
              @article_localization = ArticleLocalization.where(conditions).first
            else
              @article_localization = ArticleLocalization.where(:id => params[:localization_id]).first
            end
            @article = Article.where(:id => params[:id]).first
          end

          def authorize_user
            authorize! :manage, Gluttonberg::Article
          end

          def authorize_user_for_destroy
            authorize! :destroy, Gluttonberg::Article
          end

          def authorize_blog_for_current_user
            authorize! :manage_object, @blog
          end

          def _log_article_changes
            localization_detail = ""
            if Gluttonberg.localized?
              localization_detail = " (#{@article_localization.locale.slug}) "
            end
            if Gluttonberg.localized?
              Gluttonberg::Feed.log(current_user,@article_localization,"#{@article_localization.title}#{localization_detail}" , "updated")
            end
          end

          def all_articles
            conditions = {:blog_id => params[:blog_id]}
            @articles = Article.where( conditions).order("created_at DESC")
          end

      end
    end
  end
end
