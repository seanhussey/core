object @asset
attributes :id, :name
node(:small_thumb) { |m| @asset.url_for(:small_thumb) } 