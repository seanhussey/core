class SpamFlagForComments < ActiveRecord::Migration
  def change
    add_column :gb_comments , :spam , :boolean , :default =>  false
    add_column :gb_comments , :spam_score , :float
  end
end
