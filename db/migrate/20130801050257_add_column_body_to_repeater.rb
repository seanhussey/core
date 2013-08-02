class AddColumnBodyToRepeater < ActiveRecord::Migration
  def change
    add_column :gb_repeater, :column_body, :text
  end
end
