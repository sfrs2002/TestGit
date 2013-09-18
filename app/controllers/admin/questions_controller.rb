class Admin::QuestionsController < Admin::ApplicationController
  def new
    @question = Question.new
  end

  def create
    question = Question.create_new(params[:question])
    answer = Answer.create_new(params[:question]["type"], params[:answer])
    question.answers << answer
    redirect_to admin_question_url(question)
  end

  def show
    @question = Question.find(params[:id])
    @answers = @question.answers
  end

  def index
    @books = Structure.books
    @questions = Question.search(params[:search])
  end

  def update
    
  end

  def destroy
    
  end

  # create or update a group
  def create_group
    
  end

  # get group by question id
  def get_group
    question = Question.find(params[:id])
    @questions = questoin.question_group.questions
  end
end
