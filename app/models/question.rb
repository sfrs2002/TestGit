class Question
  include Mongoid::Document
  include Mongoid::Timestamps
  field :content, type: String
  field :tag, type: String
  has_many :answers
  belongs_to :question_group
  belongs_to :structure

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

  def self.search(str, book_id, chapter_id, section_id, subsection_id)
    if book_id.blank?
      questions = Question.all
    else
      structure = Structure.find_structure(book_id, chapter_id, section_id, subsection_id)
      questions = structure.all_questions
    end
    return questions if str.blank?
    return questions.any_of({tag: Regexp.new(str)}, {content: Regexp.new(str)})
  end

  def allocate_strucutre(book_id, chapter_id, section_id, subsection_id)
    structure = Structure.find_structure(book_id, chapter_id, section_id, subsection_id)
    structure.questions << self
  end
end
