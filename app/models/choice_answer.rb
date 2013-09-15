class ChoiceAnswer < Answer
  include Mongoid::Document
  field :choice, type: Integer

  belongs_to :choice_question

  def self.create_new(answer)
  	a_inst = ChoiceAnswer.create(choice: answer["choice"].to_i)
  	a_inst.procedures = answer["procedure"].split(/[\r\n]+/).map { |e| e.strip }
  	a_inst.save
  	a_inst
  end 
end
