class TutorController < ApplicationController

  before_action :authenticate_user!   ## User has to be logged in

  def index
    #check if user is a tutor
    unless current_user.is_tutor
      redirect_to tutor_first_time_tutor_path
    end

    @tutoring_sessions = TutoringSession.where(tutor_id: current_user.id, accepted: false)
  end

  def incoming_requests
    @tutoring_sessions = TutoringSession.where(tutor_id: current_user.id, accepted: false)
    respond_to do |format|
      format.js
    end
  end

  def accept_request
    TutoringSession.find(params[:session_id]).update(accepted: true)

    tutoring_session = TutoringSession.find(params[:session_id])
    tutor = []
    tutor << User.find(tutoring_session.tutor_id)
    @tutee = User.find(tutoring_session.user_id)

    #Taken form ChatController#index: start
    session[:conversations] ||= []


    tutoring_session = TutoringSession.where(user_id: current_user.id).or(TutoringSession.where(tutor_id: current_user.id)).last


    if !tutoring_session.nil? && tutoring_session.accepted
      @conversations = []
      @users = User.all.where(id: tutoring_session.user_id).or(User.all.where(id: tutoring_session.tutor_id)).where.not(id: current_user)                 #select all users that are not us
      @conversations << Conversation.includes(:recipient, :messages)
                                   .find_by(id: session[:conversations])
    end
    ##Taken form ChatController#index: end

    #Broadcast to tutee
    ActionCable.server.broadcast(
      "conversations-#{@tutee.id}",
      command: "tutor_accepted",
      being_tutored: ApplicationController.render(partial: 'chat/index', locals: {users: tutor, conversations: @conversations })
    )


    respond_to do |format|
      format.js
    end
  end

  def currently_tutoring
    @tutoring_sessions = TutoringSession.where(tutor_id: current_user.id, accepted: true)
    respond_to do |format|
      format.js
    end
  end

  def tutor_profile
    respond_to do |format|
      format.js
    end
  end

  def piggy_bank
    respond_to do |format|
      format.js
    end
  end

  def messenger
    respond_to do |format|
      format.js {render 'chat/index'}
    end
  end

  def first_time_tutor
    @subject = Subject.new
  end

  def get_courses
    render partial: 'select_course_tutor', locals: {subject_id: params[:subject_id]}
  end

  def get_tags
    render partial: 'course_tag_tutor', locals: {course_id: params[:course_id]}
  end

  def create
    #TutorCourse.create(tutor_course_params)
    @tutor = Tutor.new
    @tutor.user_id = current_user.id
    @tutor.total_tip = 0;
    @tutor.save()

    @user_tutor = User.find(current_user.id)
    @user_tutor.update_attributes(is_tutor: true)


    @tutor_courses = params[:course][:id]
    @tutor_courses.shift

    @tutor_courses.each do |course_id|
      TutorCourse.create(tutor_id: current_user.tutor.id, course_id: course_id.to_i)
    end



    redirect_to tutor_index_path
  end

  # def update
  #   @tutor = current_user
  #   @tutor.update_attributes(is_tutor: true)
  #   redirect_to tutor_index_path
  # end

  private

  def tutor_course_params

  end

end
