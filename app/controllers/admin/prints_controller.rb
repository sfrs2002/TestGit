# encoding: utf-8
class Admin::PrintsController < Admin::ApplicationController
  def show
    @print = Print.find(params[:id])
  end

  def index
    @prints = current_user.history_prints
  end

  def print
    print = current_user.ensure_print
    history_print = Print.create
    history_print.questions = print.questions
    history_print.save
    current_user.history_prints << history_print
    # the returned value should be the exported file address
    redirect_to print.print.scan(/public(.*)/)[0][0] and return
  end

  def destroy
    Print.find(params[:id]).destroy
    redirect_to action: :index and return
  end

  def clear
    @print = current_user.ensure_print
    @print.questions = []
    @print.save
    redirect_to action: :show, id: @print.id.to_s and return
  end

  def clone
    history_print = Print.find(params[:id])
    print = current_user.print
    print.questions = history_print.questions
    print.save
    redirect_to action: :show, id: current_user.print.id.to_s and return
  end
end
