class <%= plural_class_name %>Controller < Gluttonberg::Public::BaseController

  def index
    @<%= plural_name %> = <%= class_name %>.published<% if draggable? %>.order('position asc') <%end%>
  end

  def show
    @custom_model_object = @<%= singular_name %> = <%= class_name %>.published.where(:slug => params[:id]).first
    if @<%= singular_name %>.blank?
      @<%= singular_name %> = <%= class_name %>.published.where(:previous_slug => params[:id]).first
      unless @<%= singular_name %>.blank?
        redirect_to <%= singular_name %>_path(@<%= singular_name %>.slug) , :status => 301
      end
    end
    raise ActiveRecord::RecordNotFound.new if @<%= singular_name %>.blank?
  end

end