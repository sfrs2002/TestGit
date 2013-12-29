class User::NotesController < ApplicationController
  def index
    @notes = current_user.notes
  end

  def create
    @note = Note.create(name: params[:name])
    current_user.notes << @note
    redirect_to action: :index
  end

  def destroy
    @note = current_user.notes.find(params[:id])
    @note.destroy
    redirect_to action: :index
  end

  def show
    @note = current_user.notes.find(params[:id])
    @questions = @note.questions
  end

  def update
    @note = current_user.notes.find(params[:id])
    @note.update_attributes({name: params[:name]})
    render json: true
  end
end
