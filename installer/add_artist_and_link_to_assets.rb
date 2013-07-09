class AddArtistAndLinkToAssets < ActiveRecord::Migration
  def change
    add_column :gb_assets , :artist_name , :string
    add_column :gb_assets , :link , :string
  end
end
