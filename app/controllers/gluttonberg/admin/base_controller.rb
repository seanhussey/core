module Gluttonberg
  module Admin
    class BaseController < Gluttonberg::BaseController
       helper_method :current_user_session, :current_user
       before_filter :require_user
       before_filter :require_backend_access

       layout 'gluttonberg'
       unloadable

      protected


        # this method is used by sorter on asset listing by category and by collection
        def get_order
          order_type = params[:order_type].blank? ? "desc" : params[:order_type]
          case params[:order]
          when 'asset_name'
            "gb_assets.name #{order_type}"
          when 'first_name'
            "first_name #{order_type}"
          when 'email'
            "email #{order_type}"
          when 'role'
            "role #{order_type}"
          when 'member_groups'
            "name #{order_type}"
          when 'name'
            "name #{order_type}"
          when 'date-updated'
            "updated_at #{order_type}"
          when 'created_at'
            "created_at #{order_type}"
          else
            "created_at #{order_type}"
          end
        end


        # This is to be called from within a controller — i.e. the delete action —
        # and it will display a dialog which allows users to either confirm
        # deleting a record or cancelling the action.
        def display_delete_confirmation(opts)
          @options = opts
          @do_not_delete = (@options[:do_not_delete].blank?)? false : @options[:do_not_delete]

          unless @do_not_delete
            @options[:title]    ||= "Delete Record?"
            @options[:message]  ||= "If you delete this record, it will be gone permanently. There is no undo."
          else
            @options[:title]    = "Sorry you cannot delete this record!"
            @options[:message]  ||= "It is been used by some other records."
          end
          render :template => "gluttonberg/admin/shared/delete", :layout => "/layouts/bare"
        end

        # This is to be called from within a controller — i.e. the publish/unpublish action —
        # and it will display a dialog which allows users to either confirm
        # publish/unpublish a record or cancelling the action.
        def display_generic_confirmation(name , opts)
          @options = opts
          @do_not_do = (@options[:do_not_do].blank?)? false : @options[:do_not_do]
          @name = name

          unless @do_not_do
            @options[:title]    ||= "#{@name.capitalize} Record?"
            @options[:message]  ||= "If you #{@name.downcase} this record, it will be #{@name}"
          else
            @options[:title]    = "Sorry you cannot #{@name.capitalize} this record!"
            @options[:message]  ||= "It's parent record is not #{@name.capitalize}."
          end
          render :template => "shared/generic", :layout => "/layouts/bare"

        end

        # Generic code for destroy action. It is done trying to avoid duplication of similar code
        def generic_destroy(object, opts)
          if object.destroy
            flash[:notice] = "The #{opts[:name]} was successfully deleted."
            redirect_to opts[:success_path]
          else
            flash[:error] = "There was an error deleting the #{opts[:name]}."
            redirect_to opts[:failure_path]
          end
        end

        # Generic code for create action. It is done trying to avoid duplication of similar code
        def generic_create(object, opts)
          generic_create_or_update(object, opts)
        end

        # Generic code for update action. It is done trying to avoid duplication of similar code
        def generic_update(object, opts)
          generic_create_or_update(object, opts)
        end

        def store_location
          session[:return_to] = request.url
        end

        # Exception handlers
        def not_found
          render :layout => "bare" , :template => 'gluttonberg/admin/exceptions/not_found' , :status => 404, :handlers => [:haml], :formats => [:html]
        end

        def access_denied
          render :layout => "bare" , :template => 'gluttonberg/admin/exceptions/not_found' , :status => 403, :handlers => [:haml], :formats => [:html]
        end

      private
        def generic_create_or_update(object, opts)
          message = object.new_record? ? "created" : "updated"
          render_action = object.new_record? ? :new : :edit
          if object.save
            flash[:notice] = "The #{opts[:name]} was successfully #{message}."
            redirect_to opts[:success_path]
          else
            render render_action
          end
        end

    end
  end # Admin
end
