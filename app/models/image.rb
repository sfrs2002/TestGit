class Image
  include Mongoid::Document
  include Mongoid::Timestamps
  field :type, type: Integer
  field :file_name, type: String
  belongs_to :question
  
  USER_INSERT = 1
  MATH_EQUATION = 2
end
