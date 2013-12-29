class User::QuestionsController < User::ApplicationController
  def index
    @questions = Question.all
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "file_name", template: "user/questions/show.pdf.haml", print_media_type: true
      end
    end
  end

  def add_to_note
    @note = current_user.notes.find(params[:note_id])
    retval = @note.add_question(params[:id], description)
    render json: retval
  end

  def remove_from_note
    @note = current_user.notes.find(params[:note_id])
    retval = @note.remove_question(params[:id])
    render json: retval
  end

  def add_to_print
  	
  end

  def remove_from_print
    
  end
end
