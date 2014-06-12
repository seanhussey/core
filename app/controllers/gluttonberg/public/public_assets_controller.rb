module Gluttonberg
  module Public
    class PublicAssetsController <  ActionController::Base
        # this action redirects to actual assets url. This action is accessed using 
        # short url for assets with just 4 characters from hash and id of assets
        def show
          @asset = Asset.where("id = ? AND asset_hash like ? ", params[:id].to_i, params[:hash]+'%').first
          if @asset.blank?
            render :layout => "bare", :template => 'gluttonberg/admin/exceptions/not_found.html.haml', :status => 404
            return
          end
          if params[:thumb_name].blank?
            redirect_to @asset.url
          else
            redirect_to @asset.url_for(params[:thumb_name].to_sym)
          end
        end
    end
  end
end