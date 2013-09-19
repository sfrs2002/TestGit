class Admin::StructuresController < Admin::ApplicationController

  def create
    Structure.create_new(params[:book_id],
      params[:chapter_id],
      params[:section_id],
      params[:structure])
    redirect_to action: :index and return
  end

  def children
    structure = Structure.find(params[:id])
    @children = structure.children
    render json: { success: true, data: @children } and return
  end

  def index
    @books = Structure.books
  end

  def destroy
    @structure = Structure.find(params[:id])
    @structure.delete_children
    render json: { success: true } and return
  end
end
