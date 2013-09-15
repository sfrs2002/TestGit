class ChoiceQuestion < Question
  include Mongoid::Document
  field :items, type: Array
  field :random, type: Boolean, default: false
  field :item_num_per_row, type: Integer, default: 4

  def self.create_new(question)
    q_inst = ChoiceQuestion.create(content: question["content"],
      item_num_per_row: question["item_num_per_row"].to_i,
      source: question["source"])
    q_inst.items = question["items"].split(/[\r\n]+/).map { |e| e.strip }
    q_inst.save
    q_inst
  end
end
