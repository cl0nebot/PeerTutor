Rails.application.routes.draw do

  get 'chat/index'

  get 'tutor/index'

  get 'tutor/incoming_requests'

  get 'tutor/currently_tutoring'

  get 'tutor/tutor_profile'

  get 'tutor/piggy_bank'

  get 'tutor/messenger'

  get 'tutee/index'

  get 'tutee/find_tutor'
  post 'tutee/find_tutor' => 'tutee#create'

  get 'tutee/tutoring_sessions'

  get 'tutor/create'

  get 'tutee/list_of_tutors'

  get 'tutee/tips_management'

  get 'tutee/schedule'

  get 'tutee/messenger'

  get 'tutee/tutor_chosen'

  root 'home#index'

  get 'home/authentication'

  get 'tutor/first_time_tutor'

  post 'tutor/update'

  get 'tutor/request_accepted'


  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  resources :conversations, only: [:create] do
    member do
      post :close
    end

    resources :messages, only: [:create]
  end

  resources :tutee, only: [:find_tutor] do
    collection do
      get 'get_courses'  # /tutee/get_courses
    end
  end

end
