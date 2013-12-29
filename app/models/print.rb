class Print
  include Mongoid::Document
  include Mongoid::Timestamps
  has_many :questions
  belongs_to :user
end
