require 'RMagick'
require 'fileutils'
class Image
  include Mongoid::Document
  include Mongoid::Timestamps
  field :type, type: Integer
  field :file_name, type: String
  field :obj_file_name, type: String
  field :pro_file_name, type: String
  field :width, type: Float
  field :height, type: Float
  belongs_to :question
  
  USER_INSERT = 1
  MATH_EQUATION = 2

  def self.create_object_equation_image(file_name, obj_file_name, width, height)
    image = Image.create(type: MATH_EQUATION,
      width: width.to_f,
      height: height,
      file_name: file_name,
      obj_file_name: obj_file_name)
    return image.id.to_s
  end

  def self.create_question_image(file_name)
    image = Image.create(type: USER_INSERT,
      file_name: file_name)
    return image.id.to_s
  end

  def tidyup(question)
    image_type = file_name.scan(/\.(.*)/)[0][0]
    q_img_dir = "public/question_images/#{question.id.to_s}"
    q_img_obj_dir = "#{q_img_dir}/objects"
    q_img_ori_dir = "#{q_img_dir}/originals"
    q_img_pro_dir = "#{q_img_dir}/processed"
    if !File.directory?(q_img_dir)
      FileUtils.mkdir([q_img_dir, q_img_obj_dir, q_img_ori_dir, q_img_pro_dir])
    end
    # copy the original image file
    FileUtils.cp(file_name, "#{q_img_ori_dir}/#{self.id.to_s}.#{image_type}")
    # copy the object image binary file
    FileUtils.cp(obj_file_name, "#{q_img_obj_dir}/#{self.id.to_s}.bin") if obj_file_name.present?
    # convert to png file and save in the processed image file
    begin
      i = Magick::Image.read("#{q_img_ori_dir}/#{self.id.to_s}.#{image_type}").first
      i.trim.write("#{q_img_pro_dir}/#{self.id.to_s}.png") { self. quality = 1 }
      self.update_attributes({pro_file_name: "#{q_img_pro_dir}/#{self.id.to_s}.png"})
    rescue
      FileUtils.cp("#{q_img_ori_dir}/#{self.id.to_s}.#{image_type}",
        "#{q_img_pro_dir}/#{self.id.to_s}.#{image_type}")
      self.update_attributes({pro_file_name: "#{q_img_pro_dir}/#{self.id.to_s}.#{image_type}"})
    end
    question.images << self
  end

  def render_image
    self.pro_file_name.scan(/public(.*)/)[0][0]
  end
end
