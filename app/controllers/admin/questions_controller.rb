# encoding: utf-8
class Admin::QuestionsController < Admin::ApplicationController
  def index
    @questions = Question.where(preview: false)
  end

  def destroy
    q = Question.find(params[:id])
    q.destroy
    redirect_to action: :index
  end

  def upload_file
  end

  def file_uploaded
    document = Document.new
    document.document = params[:file]
    document.store_document!
    @parsed_qs = document.parse
    redirect_to action: :preview, ids: (@parsed_qs.map { |e| e.id.to_s }).join(',')
  end

  def preview
    @questions = Question.find(params[:ids].split(','))
  end

  def confirm
    params[:keep_q_ids].split(',').each do |q_id|
      q = Question.where(id: q_id).first
      q.update_attributes({preview: false}) if q.present?
    end
    flash[:notice] = "成功导入题目"
    redirect_to action: :index and return
  end

  def group
    group = Group.find_or_create_preview
    question = Question.find(params[:id])
    group.questions << question
    flash[:notice] = "已添加到新分组"
    redirect_to action: :index and return
  end

  def ungroup
    question = Question.find(params[:id])
    group = question.group
    group.questions.delete(question)
    if group.preview
      redirect_to new_admin_group_path and return
    else
      # redirect_to admin_group_path(id: group.id.to_s) and return
      redirect_to admin_groups_path and return
    end
  end
end
