class QuestionGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :questions

  def self.group(q_id_arr)
    q_arr = []
    q_id_arr.each do |q_id|
      q = Question.find(q_id)
      q_arr << q
      g = q.question_group.try(:remove_question, q)
    end
    self.create_group(q_arr)
  end

  def remove_question(q)
    self.questions.delete(q)
    self.destroy if self.questions.blank?
  end

  def self.create_group(q_arr)
    g = QuestionGroup.create
    g.questions.concat(q_arr)
  end
end
