class CreateAutoSave < ActiveRecord::Migration
  def change
    create_table :gb_auto_save_versions do |t|
      t.integer :auto_save_able_id
      t.string :auto_save_able_type
      t.text :data
      t.timestamps
    end
  end
end
