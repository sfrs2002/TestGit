class Structure
  include Mongoid::Document
  # 1 indicates book, 2 indicates chapter, 3 indicates section, 4 indicates subsection
  field :level, type: Integer
  field :name, type: String
  has_many :children, class_name: "Structure", inverse_of: :parent
  belongs_to :parent, class_name: "Structure", inverse_of: :children

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
    logger.info "BBBBBBBBBBBBBBBBB"
    logger.info book_id
    logger.info chapter_id
    logger.info section_id
    logger.info structure
    logger.info "BBBBBBBBBBBBBBBBB"
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
end
