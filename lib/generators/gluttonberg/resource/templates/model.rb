class <%= class_name %> < ActiveRecord::Base
  include Gluttonberg::Content::Publishable
  include Gluttonberg::Content::SlugManagement
  #self.slug_source_field_name = :name  #uncomment this line and provide your source for slug. by default it looks for name or title or id
  attr_accessible <%= attributes.collect{|attr| ":#{attr_db_name_wrapper(attr)}"}.join(",") %>, :slug, :seo_title, :seo_keywords, :seo_description, :fb_icon_id, :state, :position , :published_at
  # it validates all columns values using max limit from database schema
  validate :max_field_length
  validate :integer_values
  validate :decimal_values
  <% if localized? %>include Gluttonberg::Content::Localization
  delegate :fb_icon , :to =>  :current_localization
  <% attributes.find_all{|attr| ['asset', 'image','video','document','audio'].include?(attr.type.to_s) }.each do |attr| %>
  delegate :<%=attr_name_wrapper(attr)%> , :to =>  :current_localization
  <%end%>
  <% end %>
  <% unless localized? %>belongs_to :fb_icon , :class_name => "Gluttonberg::Asset" , :foreign_key => "fb_icon_id"<% end %>
  <% if importable? %>import_export_csv(<%=attributes.collect{|attr| "#{attr.name}"} %>) <% end %>
  <%if draggable? %>is_drag_tree :flat => true , :order => "position"<%end%>
  <% if localized? %>is_localized do
    <% if versioned? %>
    is_versioned :non_versioned_columns => []
    delegate :state, :_publish_status, :state_changed?, :title_or_name? , :to => :parent, :allow_nil => true
    <% end %>
    belongs_to :fb_icon , :class_name => "Gluttonberg::Asset" , :foreign_key => "fb_icon_id"
    # it validates all columns values using max limit from database schema
    validate :max_field_length
    validate :integer_values
    validate :decimal_values
  <% attributes.find_all{|attr| ['asset', 'image','video','document', 'audio'].include?(attr.type.to_s) }.each do |attr| %>
    belongs_to :<%=attr_name_wrapper(attr)%> , :foreign_key => "<%=attr_db_name_wrapper(attr)%>" , :class_name => "Gluttonberg::Asset"
  <% end %>end<% end %>
  <% unless localized? %><% attributes.find_all{|attr| ['asset', 'image','video','document', 'audio'].include?(attr.type.to_s) }.each do |attr| %>
  belongs_to :<%=attr_name_wrapper(attr)%> , :foreign_key => "<%=attr_db_name_wrapper(attr)%>" , :class_name => "Gluttonberg::Asset"
  <% end %><% end %>
  belongs_to :user
  <% if versioned? %>
  <% unless localized? %>is_versioned :non_versioned_columns => []<% end %>
  <% if localized? %>delegate :version, :loaded_version, :versions,  :to => :current_localization<% end %>
  <% end %>

  def title_or_name?
    <% if attributes.find{|attr| attr.name == "name"}.blank?  %><% if attributes.find{|attr| attr.name == "title"}.blank?  %>id<%else%>title<%end%><%else%>name<%end%>
  end

  def duplicate!
    @cloned_<%= singular_name %> = self.dup
    @cloned_<%= singular_name %>.position = nil
    @cloned_<%= singular_name %>.unpublish
    @cloned_<%= singular_name %>.created_at = Time.now
    if @cloned_<%= singular_name %>.save
      @cloned_<%= singular_name %>
    else
      nil
    end
  end
end