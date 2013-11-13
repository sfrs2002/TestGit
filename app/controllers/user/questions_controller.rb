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
end
