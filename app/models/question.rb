class Question
  include Mongoid::Document
  include Mongoid::Timestamps
  field :content, type: String
  # field :source, type: String
  # field :level, type: Integer
  # field :year, type: String
  # field :region, type: Integer
  field :tag, type: String
  has_many :answers

  belongs_to :question_group

  def self.create_new(question)
    Object.const_get("#{question['type']}Question").create_new(question)
  end

  after_create do |doc|
    o = [('a'..'z'), (0..9)].map { |i| i.to_a }.flatten
    tag = (0...5).map{ o[rand(o.length)] }.join
    while Question.where(tag: tag).present?
      tag = (0...5).map{ o[rand(o.length)] }.join
    end
    doc.tag = tag
    doc.save
  end

  def self.search(str)
    return Question.all if str.blank?
    return Question.any_of({tag: Regexp.new(str)}, {content: Regexp.new(str)})
  end
end
