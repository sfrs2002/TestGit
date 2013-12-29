class Note
  include Mongoid::Document
  include Mongoid::Timestamps
  # each element is a hash, keys of which include:
  # => question_id: id the of the question
  # => description: array of description
  field :question_ids, :type => Array, default: []
  field :name, :type => String, default: ""
  has_many :questions
  belongs_to :user

  def add_question(question_id, description)
    question = Question.find(question_id)
    return false if question.nil?
    if self.questions.include?(question)
      ele = self.question_ids.select { |e| e["question_id"] == question_id } .first
    else
      self.questions << question
      ele = {"question_id" => question_id, "description" => []}
    end
    ele["description"] << description if description.present?
    self.save
  end

  def remove_question(question_id)
    question = Question.find(question_id)
    return false if question.nil?
    self.questions.delete(question)
    self.question_ids.delete { |e| e["question_id"] == question_id }
    self.save
  end
end
