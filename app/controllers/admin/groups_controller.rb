class Admin::GroupsController < Admin::ApplicationController
  def index
    @groups = Group.where(preview: false)
  end

  def create
    @group = Group.where(preview: true).first
    @group.confirm
    redirect_to admin_groups_path and return
  end

  def new
    @group = Group.where(preview: true).first
  end

  def update
    
  end

  def show
    @group = Group.find(params[:id])
  end

  def destroy
    g = Group.find(params[:id])
    g.destroy
    redirect_to action: :index
  end
end
