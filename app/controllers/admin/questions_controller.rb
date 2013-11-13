class Admin::QuestionsController < Admin::ApplicationController
  def new
    @books = Structure.books
    @question = Question.new
  end

  def create
    question = Question.create_new(params[:question])
    answer = Answer.create_new(params[:question]["type"], params[:answer])
    question.answers << answer
    question.allocate_structure(params[:book_id],
      params[:chapter_id],
      params[:section_id],
      params[:subsection_id])
    redirect_to admin_question_url(question)
  end

  def show
    @question = Question.find(params[:id])
    @answers = @question.answers
  end

  def index
    @books = Structure.books
    @questions = Question.search(params[:search],
      params[:book_id],
      params[:chapter_id],
      params[:section_id],
      params[:subsection_id])
  end

  def update
    
  end

  def destroy
    
  end

  # create or update a group
  def create_group
    QuestionGroup.group(params[:q_id_arr])
    render json: { success: true } and return
  end

  # get group by question id
  def get_group
    question = Question.find(params[:id])
    @questions = questoin.question_group.questions
  end
end
