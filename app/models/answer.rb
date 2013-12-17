class Answer
  include Mongoid::Document
  field :procedures, type: Array

  belongs_to :question
  
  def self.create_new(question_type, answer)
  	Object.const_get("#{question_type}Answer").create_new(answer)
  end
end
