class GluttonbergMigration < ActiveRecord::Migration
  def change
    create_table :gb_plain_text_content_localizations do |t|
      t.integer :page_localization_id
      t.string :text, :limit => 255
      t.integer :plain_text_content_id
      t.integer :version
      t.timestamps
    end

    create_table :gb_html_contents do |t|
      t.boolean :orphaned, :default => false
      t.string :section_name, :limit => 50
      t.integer :page_id
      t.timestamps
    end

    create_table :gb_html_content_localizations do |t|
      t.text :text
      t.integer :html_content_id
      t.integer :page_localization_id
      t.integer :version
      t.timestamps
    end

    create_table :gb_textarea_contents do |t|
      t.boolean :orphaned, :default => false
      t.string :section_name, :limit => 50
      t.integer :page_id
      t.timestamps
    end

    create_table :gb_textarea_content_localizations do |t|
      t.text :text
      t.integer :textarea_content_id
      t.integer :page_localization_id
      t.integer :version
      t.timestamps
    end

    create_table :gb_image_contents do |t|
      t.boolean :orphaned, :default => false
      t.string :section_name, :limit => 50
      t.integer :asset_id
      t.integer :page_id
      t.integer :version
      t.timestamps
    end

    create_table :gb_select_contents do |t|
      t.boolean :orphaned, :default => false
      t.string :section_name, :limit => 50
      t.string :text
      t.integer :page_id
      t.integer :version
      t.timestamps
    end

    create_table :gb_locales do |t|
      t.string :name, :limit => 70, :null => false
      t.string :slug, :limit => 70, :null => false
      t.string :slug_type, :limit => 70, :null => false # prefix , subdomain
      t.boolean :default, :default => false
      t.timestamps
    end

    create_table :gb_settings do |t|
      t.string :name, :limit => 50, :null => false
      t.text :value
      t.integer :category, :default => 1
      t.integer :row
      t.boolean :delete_able, :default => true
      t.boolean :enabled, :default => true
      t.string :site
      t.text :help
      t.text :values_list
      t.timestamps
    end

    create_table :gb_page_localizations do |t|
      t.string :name, :limit => 150
      t.string :navigation_label, :limit => 100
      t.string :slug, :limit => 50
      t.string :path, :limit => 255
      t.integer :locale_id
      t.integer :page_id
      t.string :seo_title , :limit => 255
      t.text :seo_keywords
      t.text :seo_description
      t.integer :fb_icon_id
      t.string :previous_path
      t.timestamps
    end

    create_table :gb_pages do |t|
      t.integer :parent_id
      t.string :name, :limit => 100
      t.string :navigation_label, :limit => 100
      t.string :slug, :limit => 100
      t.string :description_name, :limit => 100
      t.boolean :home, :default => false
      t.integer :position
      t.integer :user_id
      t.string :state
      t.boolean :hide_in_nav
      t.datetime :published_at
      t.integer :children_count, :default => 0
      t.timestamps
    end

    create_table :gb_plain_text_contents do |t|
      t.boolean :orphaned, :default => false
      t.string :section_name, :limit => 50
      t.integer :page_id
      t.timestamps
    end

    create_table :gb_asset_categories do |t|
      t.string :name, :null => false
      t.boolean :unknown
    end

    create_table :gb_asset_types do |t|
      t.string :name, :null => false
      t.integer :asset_category_id, :default => 0
    end

    create_table :gb_asset_mime_types do |t|
      t.string :mime_type, :null => false
      t.integer :asset_type_id, :default => 0
    end

    create_table :gb_asset_collections do |t|
      t.string :name, :null => false
      t.integer :user_id
      t.timestamps
    end

    create_table :gb_assets do |t|
      t.string :mime_type
      t.integer :asset_type_id
      t.string :name, :null => false
      t.text :description
      t.string :file_name
      t.string :asset_hash
      t.integer :size
      t.boolean :custom_thumbnail
      t.text :synopsis
      t.text :copyrights
      t.integer :year_of_production
      t.string :duration
      t.integer :user_id
      t.integer :width
      t.integer :height
      t.string :alt
      t.boolean :processed
      t.boolean :copied_to_s3
      t.integer :poster_image_id
      t.timestamps
    end

    create_table :gb_audio_asset_attributes do |t|
      t.integer :asset_id , :null => false
      t.float   :length
      t.string  :title
      t.string  :artist
      t.string  :album
      t.string  :tracknum
      t.string  :genre
      t.timestamps
    end

    create_table :gb_asset_collections_assets , :id => false do |t|
      t.column :asset_collection_id, :integer, :null => false
      t.column :asset_id, :integer, :null => false
    end

    create_table :gb_users do |t|
      t.string :first_name, :null => false
      t.string :last_name
      t.string :email, :null => false
      t.string :crypted_password, :null => false
      t.string :password_salt, :null => false
      t.string :persistence_token, :null => false
      t.string :single_access_token, :null => false
      t.string :perishable_token, :null => false
      t.integer :login_count, :null => false, :default => 0
      t.string :role, :null => false
      t.text :bio
      t.integer :image_id
      t.integer :position
      t.timestamps
    end




    create_table :tags do |t|
      t.integer :taggings_count, :default => 0
      t.string :name
      t.string :slug
    end

    create_table :taggings do |t|
      t.references :tag

      # You should make sure that the column created is
      # long enough to store the required class names.
      t.references :taggable, :polymorphic => true
      t.references :tagger, :polymorphic => true

      t.string :context

      t.timestamps
    end

    add_index :taggings, :tag_id
    add_index :taggings, [:taggable_id, :taggable_type, :context]

    create_table :flags, :force => true do |t|
      t.integer :user_id
      t.integer :flaggable_id
      t.string  :flaggable_type
      t.integer :flaggable_user_id
      t.string  :reason
      t.string  :url
      t.text    :description
      t.boolean :approved
      t.boolean :moderation_required
      t.timestamps
    end

    create_table :gb_asset_thumbnails do |t|
      t.column :asset_id, :integer
      t.column :thumbnail_type, :string, :limit => 100
      t.column :user_generated , :boolean
      t.timestamps
    end

    create_table :gb_stylesheets do |t|
      t.column :name , :string , :limit => 255
      t.column :slug , :string , :limit => 255
      t.column :value, :text
      t.column :css_prefix , :string , :limit => 255
      t.column :css_postfix , :string , :limit => 255
      t.column :position , :integer
      t.timestamps
    end

    create_table :gb_members do |t|
      t.string :first_name, :null => false
      t.string :last_name
      t.string :email, :null => false
      t.string :crypted_password, :null => false
      t.string :password_salt, :null => false
      t.string :persistence_token, :null => false
      t.string :single_access_token, :null => false
      t.string :perishable_token, :null => false
      t.integer :login_count, :null => false, :default => 0
      t.text :bio
      t.string :image_file_name
      t.string :image_content_type
      t.integer :image_file_size
      t.boolean :profile_confirmed,  :default => false
      t.boolean :welcome_email_sent,  :default => false
      t.string :confirmation_key
      t.boolean :can_login , :default => true
      t.timestamps
    end

    create_table :gb_groups do |t|
      t.string :name, :null => false
      t.string :description
      t.integer :position
      t.boolean :default,  :default => false
      t.timestamps
    end

    create_table :gb_groups_members , :id => false do |t|
      t.integer :member_id, :null => false
      t.integer :group_id , :null => false
    end

    create_table :gb_groups_pages , :id => false do |t|
      t.integer :page_id, :null => false
      t.integer :group_id , :null => false
    end

    create_table :gb_galleries do |t|
      t.column :title , :string , :limit => 255
      t.column :description, :text
      t.integer :user_id
      t.column :slug , :string
      t.column :state , :string
      t.datetime :published_at
      t.boolean :collection_imported , :default => false
      t.string :seo_title , :limit => 255
      t.text :seo_keywords
      t.text :seo_description
      t.integer :fb_icon_id
      t.string :previous_path
      t.timestamps
    end

    create_table :gb_gallery_images do |t|
      t.integer  :gallery_id, :null => false
      t.integer  :asset_id, :null => false
      t.integer  :position, :null => false
      t.text     :caption
      t.text     :credits
      t.string   :artist_name
      t.string   :link
      t.timestamps
    end

    create_table :gb_feeds do |t|
      t.integer :feedable_id
      t.string  :feedable_type
      t.string  :title
      t.string  :action_type
      t.integer :user_id
      t.timestamps
    end

    create_table :gb_collapsed_pages do |t|
      t.integer :page_id
      t.integer :user_id
    end

    create_table :gb_auto_save_versions do |t|
      t.integer :auto_save_able_id
      t.string :auto_save_able_type
      t.text :data
      t.timestamps
    end

    create_table :gb_authorizations do |t|
      t.string :authorizable_type
      t.integer :authorizable_id
      t.integer :user_id
      t.boolean :allow
      t.timestamps
    end

    create_table :gb_embeds do |t|
      t.string :title
      t.string :shortcode
      t.text :body
      t.timestamps
    end

    create_table :gb_versions do |t|
      t.float :version_number, :null => false
    end

  end

end
