Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :tradelines, only: %i[index show] do
    resources :deposits, only: %i[index show create]
  end
end
