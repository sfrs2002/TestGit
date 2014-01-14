#encoding: utf-8
class Admin::GroupsController < Admin::ApplicationController
  def index
    @new_group = Group.where(preview: true).first
    @groups = Group.where(preview: false)
  end

  def create
    @group = Group.where(preview: true).first
    @group.confirm(params[:name])
    redirect_to admin_groups_path and return
  end

  def new
    @group = Group.where(preview: true).first
  end

  def update_name
    @group = Group.find(params[:id])
    @group.update_attributes(name: params[:name])
    # render json: { success: @group.save } and return
    respond_to do |format|
      format.html # show_map.haml
      format.json do
        render json: { logs: @group.save }
      end
    end
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
