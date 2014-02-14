module Admin
  class <%= plural_class_name %>Controller < Gluttonberg::Admin::BaseController
    before_filter :find_<%= singular_name %>, :only => [:show, :edit, :update, :delete, :destroy, :duplicate]
    before_filter :authorize_user , :except => [:destroy , :delete]
    before_filter :authorize_user_for_destroy , :only => [:destroy , :delete]
    <%if draggable? %>
    drag_tree <%= class_name %> , :route_name => :admin_<%= singular_name %>_move
    <%else%>
    helper_method :sort_column, :sort_direction
    <%end%>
    record_history :@<%= singular_name %>
    def index
      <%if draggable? %>
      @<%= plural_name %> = <%= class_name %>.order("position ASC ")
      <% else %>
      @<%= plural_name %> = <%= class_name %>.order(sort_column + " " + sort_direction).where(prepare_search_conditions)
      @<%= plural_name %> = @<%= plural_name %>.paginate(:page => params[:page], :per_page => Gluttonberg::Setting.get_setting("number_of_per_page_items"))
      <% end %>
    end

    def show
    end

    def new
      @<%= singular_name %> = <% if localized? %><%= class_name %>.new_with_localization<% else %><%= class_name %>.new <%end%>
    end

    def edit
      <% if localized? %>@<%= singular_name %>.load_localization(params[:locale_id]) unless params[:locale_id].blank? <%end%>
      <% if versioned? %>unless params[:version].blank?
        @version = params[:version]
        @<%= singular_name %><% if localized? %>.current_localization<% end %>.revert_to(@version)
      end<%end%>
    end

    def create
      @<%= singular_name %> = <% if localized? %><%= class_name %>.new_with_localization(params[:<%= singular_name %>])<% else %><%= class_name %>.new(params[:<%= singular_name %>]) <%end%>
      <% if versioned? %>@<%= singular_name %><% if localized? %>.current_localization<% end %>.current_user_id = current_user.id<%end%>
      if @<%= singular_name %>.save
        flash[:notice] = "The <%= singular_name.titleize.downcase %> was successfully created."
        redirect_to admin_<%= plural_name %>_path
      else
        render :new
      end
    end

    def update
      <% if localized? %>@<%= singular_name %>.load_localization(params[:locale_id]) unless params[:locale_id].blank? <%end%>
      <% if versioned? %>@<%= singular_name %><% if localized? %>.current_localization<% end %>.current_user_id = current_user.id<%end%>
      if @<%= singular_name %>.update_attributes(params[:<%= singular_name %>])
        flash[:notice] = "The <%= singular_name.titleize.downcase %> was successfully updated."
        redirect_to admin_<%= plural_name %>_path
      else
        flash[:error] = "Sorry, The <%= singular_name.titleize.downcase %> could not be updated."
        render :edit
      end
    end

    def delete
      display_delete_confirmation(
        :title      => "Delete <%= class_name %> '#{@<%= singular_name %>.id}'?",
        :url        => admin_<%= singular_name %>_path(@<%= singular_name %>),
        :return_url => admin_<%= plural_name %>_path,
        :warning    => ""
      )
    end

    def destroy
      <% if localized? %>@<%= singular_name %>.current_localization <% end %>
      if @<%= singular_name %>.destroy
        flash[:notice] = "The <%= singular_name.titleize.downcase %> was successfully deleted."
        redirect_to admin_<%= plural_name %>_path
      else
        flash[:error] = "There was an error deleting the <%= singular_name.titleize.downcase %>."
        redirect_to admin_<%= plural_name %>_path
      end
    end
    <% if importable? %>
    def import
      unless params[:csv].blank?
        @feedback = <%= class_name %>.importCSV(params[:csv].tempfile.path)
        if @feedback == true
          flash[:notice] = "All <%= plural_name.titleize.downcase %> were successfully imported."
          redirect_to admin_<%= plural_name %>_path
        end
      end
    end

    def export
      csv_data = <%= class_name %>.exportCSV(<%= class_name %>.all )
      unless csv_data.blank?
        send_data csv_data, :type => 'text/csv' , :disposition => 'attachment' , :filename => "<%= plural_name.titleize.downcase %> at #{Time.now.strftime('%Y-%m-%d')}.csv"
      end
    end
    <% end %>

    def duplicate
      @cloned_<%= singular_name %> = @<%= singular_name %>.duplicate!
      if @cloned_<%= singular_name %>
        flash[:notice] = "The <%= singular_name.titleize.downcase %> was successfully duplicated."
        redirect_to edit_admin_<%= singular_name %>_path(@cloned_<%= singular_name %>)
      else
        flash[:error] = "There was an error duplicating the <%= singular_name.titleize.downcase %>."
        redirect_to admin_<%= plural_name %>_path
      end
    end

    private

      def find_<%= singular_name %>
        @<%= singular_name %> = <%= class_name %>.find(params[:id])
        raise ActiveRecord::RecordNotFound.new if @<%= singular_name %>.blank?
      end

      def authorize_user
        authorize! :manage, <%= class_name %>
        authorize! :manage_model, "<%= class_name %>"
      end

      def authorize_user_for_destroy
        authorize! :destroy, @<%= singular_name %>
      end

      <%unless draggable? %>
      def sort_column
        <%= class_name %>.column_names.include?(params[:sort]) ? params[:sort] : "created_at"
      end

      def sort_direction
        %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
      end

      def prepare_search_conditions
        conditions = ""
        unless params[:query].blank?
          <% index = 0 %>
          <%attributes.each_with_index do |attr| %><%if ["string" , "text"].include?(attr.type.to_s) %>
            <% if index > 0 %>conditions << " OR " <%end%> <%index +=1 %>
            conditions << "<%=attr.name%> LIKE '%#{params[:query]}%'"<%end%> <%end%>
        end
        conditions
      end
      <%end%>

  end
end
