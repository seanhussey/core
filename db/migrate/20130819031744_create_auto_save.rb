class CreateAutoSave < ActiveRecord::Migration
  def change
    create_table :gb_auto_versions_save do |t|
      t.integer :auto_save_able_id
      t.string :auto_save_able_type
      t.text :data
      t.timestamps
    end
  end
end
