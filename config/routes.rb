Rails.application.routes.draw do
  get 'nearest_gas', to: 'nearest_gas#show'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
