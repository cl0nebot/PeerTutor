class TutorController < ApplicationController

  before_action :authenticate_user!   ## User has to be logged in

  def index
    #check if user is a tutor
    unless current_user.is_tutor
      redirect_to tutor_first_time_tutor_path
    end

    if current_user.is_live
      @tutoring_sessions = TutoringSession.where(tutor_id: current_user.id, accepted: false)
    else
      @not_live = true
    end
  end

  def incoming_requests
    if current_user.is_live
      @tutoring_sessions = TutoringSession.where(tutor_id: current_user.id, accepted: false)
      respond_to do |format|
        format.js
      end
    else
      respond_to do |format|
        format.js {render 'offline'}
      end
    end
  end

  def accept_request

    TutoringSession.find(params[:session_id]).update(accepted: true)

    tutoring_session = TutoringSession.find(params[:session_id])
    tutee_id = tutoring_session.user_id
    tutors = []
    tutors << User.find(tutoring_session.tutor_id)
    @tutee = User.find(tutoring_session.user_id)

    conversations = Conversation.where(recipient_id: tutors[0], sender_id: @tutee.id)

    #save location in a message
    tutee_name = User.find(tutee_id).first_name
    prompt1 = "Hey #{tutee_name}!\n"
    location = current_user.location
    prompt2 = "My location: #{location}"
    conversation = Conversation.create(sender_id: current_user.id, recipient_id: tutee_id)
    message = Message.create(body: prompt1, user_id: current_user.id, conversation_id: conversation.id)
    message = Message.create(body: prompt2, user_id: current_user.id, conversation_id: conversation.id)

    #Broadcast to tutee
    ActionCable.server.broadcast(
      "conversations-#{@tutee.id}",
      command: "tutor_accepted",
      tutor_response: ApplicationController.render(
        partial: 'tutor/temp',
        locals: {location: "", item2: "" }
      )
    )


    respond_to do |format|
      format.js {render 'chat/index'}
    end
  end

  def complete_tutoring_session
    @tutee = User.find(params[:user_id])
    @session_id = params[:session_id]
    Conversation.where(recipient_id: current_user.id, sender_id: @tutee.id).or(Conversation.where(recipient_id: @tutee.id, sender_id: current_user.id)).last.destroy
    TutoringSession.where(id: @session_id).last.destroy!
    ActionCable.server.broadcast(
      "conversations-#{@tutee.id}",
      command: "session_completed",
      tutor_id: current_user.id,
      tips_box: ApplicationController.render(partial: 'tutee/tips_management')
    )
    respond_to do |format|
      format.js {render 'incoming_requests'}
    end
  end

  def currently_tutoring
    @tutoring_sessions = TutoringSession.where(tutor_id: current_user.id, accepted: true)
    respond_to do |format|
      format.js
    end
  end

  def tutor_profile
    @tutor_courses = TutorCourse.where(tutor_id: current_user.id)
    respond_to do |format|
      format.js
    end
  end

  def tutor_profile_edit
    @course = TutorCourse.where(tutor_id: current_user.id).last
    @subject_id = @course.course.subject.id

    @tutor_courses = TutorCourse.where(tutor_id: current_user.id)
    @course_ids = @tutor_courses.map(&:course_id)

    @courses = Course.where(subject_id: @subject_id)

    respond_to do |format|
      format.js
    end
  end

  def get_courses_tutor_profile
    @tutor_courses = TutorCourse.where(tutor_id: current_user.id)
    @course_ids = @tutor_courses.map(&:course_id)

    @courses = Course.where(subject_id: params[:subject_id])
    render partial: 'select_courses_tutor_profile'
  end

#-----------------------------------------------#
# note:
# using create instead of edit on purpose
# drop the row for unchecked ones and create row for newly checked ones
#-----------------------------------------------#
  def tutor_profile_update
    @course_ids = params[:course][:id].map(&:to_i)
    @tutor_courses = TutorCourse.where(tutor_id: current_user.id)

    for tutor_course in @tutor_courses
      if @course_ids.include? tutor_course.course_id   #true
        @course_ids.delete(tutor_course.course_id)
      else #false => delete the row
        TutorCourse.find(tutor_course.id).destroy
      end
    end

    for course_id in @course_ids
      TutorCourse.create(tutor_id: current_user.id, course_id: course_id)
    end

    #redirect_to tutor_index_path   #want to redirect to tutor_profile!!
    #MANSUR CODE
    respond_to do |format|
      format.js {redirect_to '/tutor/tutor_profile'}
    end
    #MANSUR CODE end

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
    @user_tutor = User.find(current_user.id)
    @user_tutor.update_attributes(is_tutor: true)

    @tutor_courses = params[:course][:id]
    @tutor_courses.shift

    @tutor_courses.each do |course_id|
      TutorCourse.create(tutor_id: current_user.id, course_id: course_id.to_i)
    end

    redirect_to tutor_index_path
  end

  def toggle_is_live
    if current_user.is_live
      current_user.update_attributes(is_live: false)

      unless current_user.location.nil?
        current_user.update_attributes(location: nil)
      end

      respond_to do |format|
        format.js { render 'offline'}
      end
    else
      current_user.update_attributes(is_live: true)
      @tutoring_sessions = TutoringSession.where(tutor_id: current_user.id, accepted: false)
      respond_to do |format|
        format.js { render 'location'}
      end
    end
  end

  def add_location
    location = params[:location][:location]
    if current_user.update_attributes(location: location)
      respond_to do |format|
        format.js {render 'incoming_requests'}
      end
    else
      respond_to do |format|
        format.js {render 'offline'}
      end
    end
  end

  def decline_request
    TutoringSession.find(params[:session_id]).update_attributes(tutor_id: nil)
    session = TutoringSession.find(params[:session_id])
    tutee_id = session.user_id
    course_id = session.course_id
    ActionCable.server.broadcast(
      "conversations-#{tutee_id}",
      command: "session_declined",
      tutor_id: current_user.id,
      partial: ApplicationController.render(partial: 'tutee/list_of_tutors', locals: {available_tutors: available_tutors(session), tutoring_session: session})
    )
    respond_to do |format|
      format.js {render 'incoming_requests'}
    end
  end

  private

  def tutor_course_params

  end

  def available_tutors(session)
    @tutors = User.where(is_tutor: true, is_live: true).where.not(id: session.user_id, location: nil).all  # @tutors.ids returns the array of live_tutor's ids

    course_tutor_ids = Array.new

    @tutors.each do |d|
      @course_tutor = TutorCourse.where(tutor_id: d, course_id: session.course_id.to_i).first
      if !@course_tutor.nil?
        course_tutor_ids << User.find(@course_tutor.tutor_id)
      else
      end
    end
    @available_tutors = course_tutor_ids

  end

end
