require 'rqrcode_png'
class Question
  include Mongoid::Document
  include Mongoid::Timestamps
  field :type, type: Integer
  field :content, type: String
  field :question_images, type: Array, default: []
  field :image_uuid, type: String, default: ""
  field :items, type: Array, default: []
  field :choice_mode, type: Integer
  field :preview, type: Boolean, default: true
  has_many :images, dependent: :delete
  belongs_to :group

  CHOICE_QS = 0
  BLANK_QS = 1
  ANALYSIS_QS = 2

  ONE_LINE = 0
  TWO_LINE = 1
  FOUR_LINE = 2


  before_destroy do |doc|
    # delete images, and the image directory if it is empty
  end

  after_create do |doc|
    # create question images folder
    q_img_dir = "public/question_images/#{doc.id.to_s}"
    q_img_obj_dir = "#{q_img_dir}/objects"
    q_img_ori_dir = "#{q_img_dir}/originals"
    q_img_pro_dir = "#{q_img_dir}/processed"
    FileUtils.mkdir([q_img_dir, q_img_obj_dir, q_img_ori_dir, q_img_pro_dir])
    # create the QR code image
    qr = RQRCode::QRCode.new("http://localhost:3000/q/#{doc.id.to_s}", :size => 4, :level => :h )
    png = qr.to_img
    png.resize(90, 90).save("#{q_img_dir}/#{doc.id.to_s}.png")
  end

  def self.create_choice_question(q, choice_mode)
    q = Question.create(type: CHOICE_QS,
      content: q[:content],
      question_images: q[:question_images],
      image_uuid: q[:image_uuid],
      items: q[:items],
      choice_mode: choice_mode)
      q.tidyup_images
  end

  def self.create_blank_question(q)
    q = Question.create(type: BLANK_QS,
      content: q[:content],
      question_images: q[:question_images])
    q.tidyup_images
  end

  def self.create_analysis_question(q)
    q = Question.create(type: ANALYSIS_QS,
      content: q[:content],
      question_images: q[:question_images])
    q.tidyup_images
  end

  def tidyup_images
    self.question_images.each do |image_id|
      image = Image.find(image_id)
      image.tidyup(self)
    end
    self.content.scan(/<equation>(.*?)<\/equation>/).each do |image_id|
      image = Image.find(image_id[0])
      image.tidyup(self)
    end
    return self if self.type != CHOICE_QS
    self.items.each do |item|
      item["content"].scan(/<equation>(.*?)<\/equation>/).each do |image_id|
        image = Image.find(image_id[0])
        image.tidyup(self)
      end  
      (item["images"] || []).each do |image_id|
        image = Image.find(image_id)
        image.tidyup(self)
      end
    end
    self
  end
end
