class TutorController < ApplicationController

  before_action :authenticate_user!   ## User has to be logged in

  def index
    #check if user is a tutor
    unless current_user.is_tutor
      redirect_to tutor_first_time_tutor_path
    end
  end

  def incoming_requests
    @tutoring_sessions = TutoringSession.where(tutor_id: current_user.id)
  end

  def currently_tutoring
  end

  def tutor_profile
  end

  def piggy_bank
  end

  def messenger
  end

  def first_time_tutor
  end

  def update
    @tutor = current_user
    @tutor.update_attributes(is_tutor: true)
    redirect_to tutor_index_path
  end

end
