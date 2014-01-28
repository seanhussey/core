class Create<%= class_name %> < ActiveRecord::Migration

  def change
    create_table :<%= table_name %> do |t|
    <% unless localized? %><% attributes.each do |attribute| -%>
  t.<%= attr_db_type_wrapper(attribute)%> :<%= attr_db_name_wrapper(attribute) %>
    <% end -%> <% end %>
      t.string :slug
      t.string :previous_slug
      t.integer :position
      t.column :state , :string #use for publishing
      t.datetime :published_at
      <% unless localized? %>
      t.string :seo_title
      t.text :seo_keywords
      t.text :seo_description
      t.integer :fb_icon_id
      t.integer :parent_id
      t.integer :locale_id
      <%end%>
      t.integer :user_id
      t.timestamps
    end
    <% if localized? %>
    create_table :<%= singular_name %>_localizations do |t|
  <% attributes.each do |attribute| -%>
    t.<%= attr_db_type_wrapper(attribute)%> :<%= attr_db_name_wrapper(attribute) %>
  <% end -%>
    t.string :seo_title
      t.text :seo_keywords
      t.text :seo_description
      t.integer :fb_icon_id
      t.integer :parent_id
      t.integer :locale_id
      t.timestamps
    end
    <% end %>
  end

end