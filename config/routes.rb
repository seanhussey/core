Rails.application.routes.draw do
  mount_at = Gluttonberg::Engine.config.mount_at

  scope :module => 'gluttonberg' do
    namespace :admin do
      root :to => "main#index"
      get "waiting-for-approval" => "main#waiting_for_approval" , :as => :waiting_for_approval
      get "decline-content/:object_class/:version_id" => "main#decline_content" , :as => :decline_content
      

      scope :module => 'content' do
        controller :auto_save do
          match "/autosave/:model_name/:id" => :create , :as => :autosave
          get "/remove_autosaved_version/:model_name/:id" => :destroy , :as => :remove_autosaved_version
          get "/retreive_changes/:model_name/:id" => :retreive_changes , :as => :retreive_changes
        end

        get "/flagged_contents" => "flag#index" , :as => :flagged_contents
        get '/flagged_contents/moderation/:id/:moderation' => "flag#moderation", :as => :flagged_contents_moderation

        resources :pages do
          member do
            get 'delete'
            get 'duplicate'
            get 'collapse'
            get 'expand'
          end
          collection do
            post 'move' =>  :move_node, :as => :move
            post 'update_home', :as =>  :update_home
            match 'import'
            get 'export'
            get 'collapse_all'
            get 'expand_all'
          end

          resources :page_localizations
        end
        get "pages_list_for_tinymce" => "pages#pages_list_for_tinymce" , :as => :pages_list_for_tinymce

        post "/pages/move(.:format)" => "pages#move_node" , :as=> :page_move
        resources :galleries do
          get 'delete', :on => :member
        end
        post "/galleries/move(.:format)" => "galleries#move_node" , :as=> :gallery_move

      end

      # Settings
      scope :module => 'settings' do
        get 'history' => "global_history#index",      :as => :global_history
        resources :locales do
          get 'delete', :on => :member
        end

        resources :users do
          get 'delete', :on => :member
        end

        resources :configurations do
          get 'delete', :on => :member
        end

        resources :stylesheets do
          get 'delete', :on => :member
        end
        post "/stylesheets/move(.:format)" => "stylesheets#move_node" , :as=> :stylesheet_move

        resources :embeds do
          get 'delete', :on => :member
          get 'list-for-redactor' => :list_for_redactor, :on => :collection
        end
      end

      namespace :membership do
        root :to =>  "main#index"
        post "/groups/move(.:format)" => "groups#move_node" , :as=> :group_move
        get "members/export" => "members#export" , :as => :members_export
        get 'members/new_bulk'  => "members#new_bulk" , :as => :members_import
        post 'members/create_bulk' => "members#create_bulk" , :as => :members_bulk_create
        resources :members do
          get 'delete', :on => :member
          get 'welcome' , :on => :member
        end
        resources :groups do
          get 'delete', :on => :member
        end
      end


      scope :module => 'asset_library' do
        # asset library related routes
        resources :assets do
          get 'delete', :on => :member
          get 'crop', :on => :member
          post 'save_crop', :on => :member
        end
        get "library" => "assets#index" , :as => :library
        get "search_assets" => "assets#search" , :as => :library_search
        post "add_asset_using_ajax"  => "assets_ajax#create" , :as => :add_asset_using_ajax
        get "add_assets_in_bulk"  => "assets_bulk#add_assets_in_bulk" , :as => :add_assets_in_bulk
        post "create_assets_in_bulk"  => "assets_bulk#create_assets_in_bulk" , :as => :create_assets_in_bulk
        post "destroy_assets_in_bulk"  => "assets_bulk#destroy_assets_in_bulk" , :as => :destroy_assets_in_bulk
        get "browser"  => "assets#browser" , :as => :asset_browser
        get "browser-collection/:id"  => "assets_ajax#browser_collection" , :as => :asset_browser_collection
        get "assets/:category/page/:page"  => "assets#category" , :as => :asset_category
        get "collections/:id/page/:page"  => "collections#show" , :as => :asset_collection
        resources :collections  do
          get 'delete', :on => :member
        end
      end

      resources :password_resets

      get "login" => "user_sessions#new", :as => :login
      post "login" => "user_sessions#create"
      get "logout" => "user_sessions#destroy", :as => :logout
    end

    scope :module => 'public' do
      get "/user_asset/:hash/:id(/:thumb_name)" => "public_assets#show" , :as => :public_asset
      get "/_public/page" => "pages#show"
      get "/restrict_site_access" => "pages#restrict_site_access" , :as => :restrict_site_access
      get "sitemap" => "pages#sitemap" , :as => :sitemap

      get "/mark_as_flag/:flaggable_type/:flaggable_id" => "flag#new" , :as => :mark_as_flag
      post "/save_mark_as_flag" => "flag#create" , :as => :save_mark_as_flag
      get "(/:locale)/member/login" => "member_sessions#new" , :as => :member_login
      post "(/:locale)/member/login" => "member_sessions#create"  , :as => :member_login
      get "(/:locale)/member/logout" => "member_sessions#destroy", :as => :member_logout
      get "(/:locale)/member/confirm/:key" => "members#confirm", :as => :member_confirmation
      get "(/:locale)/member/resend_confirmation" => "members#resend_confirmation", :as => :member_resend_confirmation
      put "(/:locale)/member/profile" => "members#update"
      get "(/:locale)/member/profile" => "members#show", :as => :member_profile
      get "(/:locale)/member/profile/edit" => "members#edit", :as => :member_profile_edit

      scope "(/:locale)" do
        resources :members
        resources :member_password_resets
      end

      get 'stylesheets/:id' => "pages#stylesheets", :as =>  :stylesheets
    end


  end

  scope :module => 'gluttonberg' do
    scope :module => 'public' do
      get "*a" => "pages#error_404"
    end
  end
end
