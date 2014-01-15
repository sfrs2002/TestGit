# encoding: utf-8
class Print
  include Mongoid::Document
  include Mongoid::Timestamps
  field :name, type: String, default: "未命名打印纸"
  has_and_belongs_to_many :questions
  belongs_to :user, class_name: "User", inverse_of: :print
  belongs_to :history_user, class_name: "User", inverse_of: :history_prints

  def print
    question_id_ary = self.questions.map { |e| e.id.to_s }
    Export.new(question_id_ary).export
  end

  def is_current_print?
    self.user.present?
  end
end
