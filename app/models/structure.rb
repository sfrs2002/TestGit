class Structure
  include Mongoid::Document
  # 1 indicates book, 2 indicates chapter, 3 indicates section, 4 indicates subsection
  field :level, type: Integer
  field :name, type: String
  has_many :children, class_name: "Structure", inverse_of: :parent
  belongs_to :parent, class_name: "Structure", inverse_of: :children
  has_many :questions

  BOOK = 1
  CHAPTER = 2
  SECTION = 3
  SUBSECTION = 4

  scope :books, -> { where(level: 1) }

  def delete_children
    self.children.each do |e|
      e.delete_children
    end
    self.destroy
  end

  def self.create_new(book_id, chapter_id, section_id, structure)
    p_id = section_id if section_id.present?
    p_id ||= chapter_id if chapter_id.present?
    p_id ||= book_id if book_id.present?
    p = Structure.find(p_id) if p_id.present?
    s = Structure.create(name: structure)
    level = p.present? ? p.level + 1 : BOOK
    s.update_attributes(level: level)
    p.children << s if p.present?
    s
  end

  def self.find_structure(book_id, chapter_id, section_id, subsection_id)
    structure_id = subsection_id if subsection_id.present?
    structure_id ||= section_id if section_id.present?
    structure_id ||= chapter_id if chapter_id.present?
    structure_id ||= book_id if book_id.present?
    return Structure.find(structure_id)
  end

  def all_questions
    structure_id_arr = self.children_id([])
    return Question.where(:structure_id.in => structure_id_arr)
  end

  def children_id(arr)
    arr << self.id
    self.children.each do |e|
      e.children_id(arr)
    end
    return arr
  end
end
