class CreateRepeater < ActiveRecord::Migration
  def change
    create_table :gb_repeater do |t|
      t.text :title
      t.integer :repeatable_id
      t.string  :repeatable_type
      t.integer :itemable_id
      t.string  :itemable_type
      t.integer :position 
      t.string  :type
      t.timestamps
    end
  end
end
