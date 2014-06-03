Rails.application.routes.draw do
  resources :blogs, only: [:show], subdomainify: true do
    resources :articles, only: [:show]
  end

  root to: "blogs#index"
end
