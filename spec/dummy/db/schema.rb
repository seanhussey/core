# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130403011606) do

  create_table "flags", :force => true do |t|
    t.integer  "user_id"
    t.integer  "flaggable_id"
    t.string   "flaggable_type"
    t.integer  "flaggable_user_id"
    t.string   "reason"
    t.string   "url"
    t.text     "description"
    t.boolean  "approved"
    t.boolean  "moderation_required"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "gb_asset_categories", :force => true do |t|
    t.string  "name",    :null => false
    t.boolean "unknown"
  end

  create_table "gb_asset_collections", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.integer  "user_id"
  end

  create_table "gb_asset_collections_assets", :id => false, :force => true do |t|
    t.integer "asset_collection_id", :null => false
    t.integer "asset_id",            :null => false
  end

  create_table "gb_asset_mime_types", :force => true do |t|
    t.string  "mime_type",                    :null => false
    t.integer "asset_type_id", :default => 0
  end

  create_table "gb_asset_thumbnails", :force => true do |t|
    t.integer  "asset_id"
    t.string   "thumbnail_type", :limit => 100
    t.boolean  "user_generated"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "gb_asset_types", :force => true do |t|
    t.string  "name",                             :null => false
    t.integer "asset_category_id", :default => 0
  end

  create_table "gb_assets", :force => true do |t|
    t.string   "mime_type"
    t.integer  "asset_type_id"
    t.string   "name",               :null => false
    t.text     "description"
    t.string   "file_name"
    t.string   "asset_hash"
    t.integer  "size"
    t.boolean  "custom_thumbnail"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "synopsis"
    t.text     "copyrights"
    t.integer  "year_of_production"
    t.integer  "created_by"
    t.integer  "updated_by"
    t.string   "duration"
    t.integer  "user_id"
    t.integer  "width"
    t.integer  "height"
    t.string   "alt"
    t.boolean  "processed"
    t.boolean  "copied_to_s3"
    t.string   "artist_name"
    t.string   "link"
  end

  create_table "gb_audio_asset_attributes", :force => true do |t|
    t.integer  "asset_id",   :null => false
    t.float    "length"
    t.string   "title"
    t.string   "artist"
    t.string   "album"
    t.string   "tracknum"
    t.string   "genre"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "gb_feeds", :force => true do |t|
    t.integer  "feedable_id"
    t.string   "feedable_type"
    t.string   "title"
    t.string   "action_type"
    t.integer  "user_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "gb_galleries", :force => true do |t|
    t.string   "title"
    t.text     "description"
    t.integer  "user_id",                                :null => false
    t.string   "slug"
    t.string   "state"
    t.datetime "published_at"
    t.boolean  "collection_imported", :default => false
    t.string :seo_title , :limit => 255
    t.text :seo_keywords
    t.text :seo_description
    t.integer :fb_icon_id
    t.string :previous_path
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false

  end

  create_table "gb_gallery_images", :force => true do |t|
    t.integer  "gallery_id", :null => false
    t.integer  "asset_id",   :null => false
    t.integer  "position",   :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.text     "caption"
    t.text     "credits"
    t.string   "artist_name"
    t.string   "link"
  end

  create_table "gb_groups", :force => true do |t|
    t.string   "name",                           :null => false
    t.string   "description"
    t.integer  "position"
    t.boolean  "default",     :default => false
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
  end

  create_table "gb_groups_members", :id => false, :force => true do |t|
    t.integer "member_id", :null => false
    t.integer "group_id",  :null => false
  end

  create_table "gb_groups_pages", :id => false, :force => true do |t|
    t.integer "page_id",  :null => false
    t.integer "group_id", :null => false
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

  create_table "gb_html_content_localizations", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "text"
    t.integer  "html_content_id"
    t.integer  "page_localization_id"
    t.integer  "version"
  end

  create_table "gb_html_contents", :force => true do |t|
    t.boolean  "orphaned",                   :default => false
    t.string   "section_name", :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "page_id"
  end

  create_table "gb_image_contents", :force => true do |t|
    t.boolean  "orphaned",                   :default => false
    t.string   "section_name", :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "asset_id"
    t.integer  "page_id"
    t.integer  "version"
  end

  create_table :gb_select_contents do |t|
    t.boolean :orphaned, :default => false
    t.string :section_name, :limit => 50
    t.string :text
    t.integer :page_id
    t.integer :version
    t.timestamps
  end


  create_table "gb_locales", :force => true do |t|
    t.string  "name",      :limit => 70,                    :null => false
    t.string  "slug",      :limit => 70,                    :null => false
    t.string  "slug_type", :limit => 70,                    :null => false
    t.boolean "default",                 :default => false
  end

  create_table "gb_members", :force => true do |t|
    t.string   "first_name",                             :null => false
    t.string   "last_name"
    t.string   "email",                                  :null => false
    t.string   "crypted_password",                       :null => false
    t.string   "password_salt",                          :null => false
    t.string   "persistence_token",                      :null => false
    t.string   "single_access_token",                    :null => false
    t.string   "perishable_token",                       :null => false
    t.integer  "login_count",         :default => 0,     :null => false
    t.text     "bio"
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.boolean  "profile_confirmed",   :default => false
    t.boolean  "welcome_email_sent",  :default => false
    t.string   "confirmation_key"
    t.boolean  "can_login",           :default => true
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  create_table "gb_page_localizations", :force => true do |t|
    t.string   "name",             :limit => 150
    t.string   "navigation_label", :limit => 100
    t.string   "slug",             :limit => 50
    t.string   "path"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "locale_id"
    t.integer  "page_id"
    t.string   "seo_title"
    t.text     "seo_keywords"
    t.text     "seo_description"
    t.integer  "fb_icon_id"
    t.string   "previous_path"
  end

  create_table "gb_pages", :force => true do |t|
    t.integer  "parent_id"
    t.string   "name",             :limit => 100
    t.string   "navigation_label", :limit => 100
    t.string   "slug",             :limit => 100
    t.string   "description_name", :limit => 100
    t.boolean  "home",                            :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.integer  "user_id"
    t.string   "state"
    t.boolean  "hide_in_nav"
    t.datetime "published_at"
    t.integer  "children_count", :default => 0
  end

  create_table "gb_plain_text_content_localizations", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "page_localization_id"
    t.string   "text"
    t.integer  "plain_text_content_id"
    t.integer  "version"
  end

  create_table "gb_plain_text_contents", :force => true do |t|
    t.boolean  "orphaned",                   :default => false
    t.string   "section_name", :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "page_id"
  end

  create_table "gb_settings", :force => true do |t|
    t.string  "name",        :limit => 50,                   :null => false
    t.text    "value"
    t.integer "category",                  :default => 1
    t.integer "row"
    t.boolean "delete_able",               :default => true
    t.boolean "enabled",                   :default => true
    t.string  "site"
    t.text    "help"
    t.text    "values_list"
  end

  create_table "gb_stylesheets", :force => true do |t|
    t.string   "name"
    t.string   "slug"
    t.text     "value"
    t.string   "css_prefix"
    t.string   "css_postfix"
    t.integer  "position"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.integer  "version"
  end

  create_table "gb_users", :force => true do |t|
    t.string   "first_name",                         :null => false
    t.string   "last_name"
    t.string   "email",                              :null => false
    t.string   "crypted_password",                   :null => false
    t.string   "password_salt",                      :null => false
    t.string   "persistence_token",                  :null => false
    t.string   "single_access_token",                :null => false
    t.string   "perishable_token",                   :null => false
    t.integer  "login_count",         :default => 0, :null => false
    t.string   "role",                               :null => false
    t.text     "bio"
    t.integer  "image_id"
    t.integer  "position"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  create_table "gb_versions", :force => true do |t|
    t.float "version_number", :null => false
  end

  create_table "html_content_localization_versions", :force => true do |t|
    t.integer  "html_content_localization_id"
    t.integer  "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "text"
    t.integer  "html_content_id"
    t.integer  "page_localization_id"
  end

  create_table "image_content_versions", :force => true do |t|
    t.integer  "image_content_id"
    t.integer  "version"
    t.boolean  "orphaned",                       :default => false
    t.string   "section_name",     :limit => 50
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "asset_id"
    t.integer  "page_id"
  end

  add_index "image_content_versions", ["image_content_id"], :name => "index_image_content_versions_on_image_content_id"

  create_table "plain_text_content_localization_versions", :force => true do |t|
    t.integer  "plain_text_content_localization_id"
    t.integer  "version"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "page_localization_id"
    t.string   "text"
    t.integer  "plain_text_content_id"
  end

  create_table "stylesheet_versions", :force => true do |t|
    t.integer  "stylesheet_id"
    t.integer  "version"
    t.string   "name"
    t.string   "slug"
    t.text     "value"
    t.string   "css_prefix"
    t.string   "css_postfix"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stylesheet_versions", ["stylesheet_id"], :name => "index_stylesheet_versions_on_stylesheet_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
    t.string "slug"
  end


  create_table :staff_profiles, :force => true do |t|
    t.string :name
    t.integer :face_id
    t.decimal :package, :precision => 6, :scale => 3

    t.string :slug
    t.string :previous_slug
    t.integer :position
    t.column :state , :string #use for publishing
    t.datetime :published_at
    t.integer :user_id

    t.timestamps
  end

  create_table :staff_profile_localizations, :force => true do |t|
    t.text :bio
    t.integer :handwritting_id

    t.string :seo_title
    t.text :seo_keywords
    t.text :seo_description
    t.integer :fb_icon_id
    t.integer :parent_id
    t.integer :locale_id
    t.timestamps
  end

  begin
    Gluttonberg::TextareaContentLocalization.create_versioned_table
  rescue => e
    puts e
  end

  begin
    Gluttonberg::SelectContent.create_versioned_table
  rescue => e
    puts e
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

end
