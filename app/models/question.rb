class Question
  include Mongoid::Document
  include Mongoid::Timestamps
  field :content, type: String
  field :source, type: String
  has_many :answers    

  def self.create_new(question)
    Object.const_get("#{question['type']}Question").create_new(question)
  end
end
