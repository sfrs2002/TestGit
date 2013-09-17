class Structure
  include Mongoid::Document
  # 1 indicates book, 2 indicates chapter, 3 indicates section, 4 indicates subsection
  field :level, type: Integer
  field :name, type: String
  has_many :children, class_name: :Structure, inverse_of: :parent
  belongs_to :parent, class_name: :Structure, inverse_of: :children

  BOOK = 1
  CHAPTER = 2
  SECTION = 3
  SUBSECTION = 4

  scope :books, -> { where(level: 1) }

end
