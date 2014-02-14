class CreateStaffProfile < ActiveRecord::Migration

  def change
    create_table :staff_profiles do |t|
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

    create_table :staff_profile_localizations do |t|
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

  end


end