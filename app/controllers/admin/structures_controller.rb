class Admin::StructuresController < Admin::ApplicationController

  def create
    
  end

  def new
    
  end

  def children
    structure = Structure.find(params[:id])
    @children = structure.children
  end

  def index
    @books = Structure.books
  end
end
