class Question
  include Mongoid::Document
  include Mongoid::Timestamps
  field :type, type: Integer
  field :content, type: String
  field :images, type: Array, default: []
  field :image_uuid, type: String, default: ""
  field :items, type: Array, default: []
  field :choice_mode, type: Integer
  field :preview, type: Boolean, default: true
  has_many :images, dependent: :delete

  CHOICE_QS = 0
  BLANK_QS = 1
  ANALYSIS_QS = 2

  ONE_LINE = 0
  TWO_LINE = 1
  FOUR_LINE = 2


  before_destroy do |doc|
    # delete images, and the image directory if it is empty
  end

  def self.create_choice_question(q, choice_mode)
    q = Question.create(type: CHOICE_QS,
      content: q[:content],
      images: q[:images],
      image_uuid: q[:image_uuid],
      items: q[:items],
      choice_mode: choice_mode)
    q.create_images
  end

  def self.create_blank_question(q)
    q = Question.create(type: BLANK_QS,
      content: q[:content],
      images: q[:images])
    q.create_images
  end

  def self.create_analysis_question(q)
    q = Question.create(type: ANALYSIS_QS,
      content: q[:content],
      images: q[:images])
    q.create_images
  end

  def create_images
    self.images.each do |image_name|
      img = Image.create(type: Image::USER_INSERT, file_name: image_name)
      self.images << img
    end
    self.content.scan(/<equation>(.*?)<\/equation>/).each do |equ_file_name|
      img = Image.create(type: Image::MATH_EQUATION, file_name: equ_file_name[0])
      self.images << img
    end
    return self if self.type != CHOICE_QS
    self.items.each do |item|
      item["content"].scan(/<equation>(.*?)<\/equation>/).each do |equ_file_name|
        img = Image.create(type: Image::MATH_EQUATION, file_name: equ_file_name[0])
        self.images << img
      end  
      (item["images"] || []).each do |image_name|
        img = Image.create(type: Image::USER_INSERT, file_name: image_name)
        self.images << img
      end
    end
    self
  end

  def render_equation
    self[:content_with_equations] = []
    
  end
end
