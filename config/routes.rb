Rails.application.routes.draw do
  root 'topics#index'

  resources :topics, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    resources :comments

    collection do
      post :confirm
    end
  end

  devise_for :users, controllers: {
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  resources :users, only: [:index]
  resources :relationships, only: [:create, :destroy]

  # メッセージ機能のルーティング
  resources :conversations do
    resources :messages
  end
end
