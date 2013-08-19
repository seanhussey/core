Rails.application.routes.draw do
  namespace :admin do  
    resources :staff_profiles do
      member do
        get 'delete'
        get 'duplicate'
      end
    end
  end
end
