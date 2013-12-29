# encoding: utf-8
require 'fileutils'
require 'zip'
require 'RMagick'
class Document
  extend CarrierWave::Mount
  mount_uploader :document, DocumentUploader

  attr_accessor :uuid, :main_xml, :image_relation_xml, :image_relation, :image_dir, :image_name_map

  def initialize
    self.uuid = SecureRandom.uuid
  end

  CHOICE_QS = 0
  BLANK_QS = 1
  ANALYSIS_QS = 2

  ONE_LINE = 0
  TWO_LINE = 1
  FOUR_LINE = 2

  def parse
    filename = "public/uploads/documents/#{self.uuid}"
    self.image_dir = FileUtils.mkpath("public/temp_images/#{self.uuid}")[0]
    # get the xml document and the image files
    self.image_name_map = {}
    Zip::File.open(filename) do |zipfile|
      zipfile.each do |entry|
        Rails.logger.info entry.name
        # obtain content from the main document: document.xml
        self.main_xml = Nokogiri::XML(entry.get_input_stream.read) if entry.name == "word/document.xml"
        # obtain corresponding relations between images and elements in document.xml
        self.image_relation_xml = Nokogiri::XML(entry.get_input_stream.read) if entry.name == "word/_rels/document.xml.rels"
        # save image files
        if entry.name.match("word/media/image").present?
          name = entry.name.split('/')[-1]
          # save the image file
          File.open("#{self.image_dir}/#{name}", 'wb') {|file| file.write(entry.get_input_stream.read) }
          # the wmf image cannot be displayed in most browsers, need to be converted into png images
          if name.end_with?(".wmf")
            begin
              i = Magick::Image.read("#{self.image_dir}/#{name}").first
            rescue
              next
            end
            old_name = name
            name = name.gsub(".wmf", ".png")
            self.image_name_map[old_name] = name
            # trim surrounding space and save the new format image
            i.trim.write("#{self.image_dir}/#{name}") { self. quality = 1 }
            # delete the old format image
            File.delete("#{self.image_dir}/#{old_name}")
          end
        end
      end
    end
    return nil if self.main_xml.nil?

    # parse the relation between images and ids, and save in the image_relation instance varialbe
    analyze_image_relation

    # parse question
    image_index = 0
    parsed_questions = []
    q = { content: [], pure_text: [], question_images: [] }
    ###
    para_index_ary = []
    question_para_map = {}
    ###
    self.main_xml.at('//w:body').elements.each_with_index do |e, index|
      # each element here is a paragraph
      contents = e.xpath('.//w:r')
      if contents.blank?
        # this paragraph has no content, the previous might be one question
        parsed_questions << self.parse_one_question(q) if q[:content].present?
        q = {content: [], pure_text: [], question_images: []}
      else
        # this paragraph has contents
        p = {content: "", pure_text: ""}
        contents.each do |content|
          # the content is text
          if content.xpath('.//w:t').present?
            # should be text
            text = content.at('.//w:t')
            if text.present?
              text = text.children[0].text
              # text is a blank string, check whether there is underline
              text.gsub!(' ', '_') if content.xpath('.//w:u').present? if text.blank?
              p[:content] += text
              p[:pure_text] += text
            end
          elsif content.xpath('.//w:object').present?
            # should be an equation
            object = content.at('.//w:object')
            rid = object.at('.//v:imagedata').attributes["id"].value
            p[:content] += "<equation>#{self.image_relation[rid]}</equation>"
            p[:pure_text] += "--equation--"
            image_index += 1
          elsif content.xpath('.//w:drawing').present?
            drawing = content.at('.//w:drawing')
            rid = drawing.at('.//a:blip', "a" => "http://schemas.openxmlformats.org/drawingml/2006/main").attributes["embed"].value
            # judge whether it is an equation or figure based on the size of the image
            if self.is_equation_image?(self.image_relation[rid])
              # this image is equation
              p[:content] += "<equation>#{self.image_relation[rid]}</equation>"
              p[:pure_text] += "--equation--"
            else
              # this image is figure
              q[:question_images] << self.image_relation[rid]
            end
            image_index += 1
          end
        end
        q[:content] << p[:content]
        q[:pure_text] << p[:pure_text] if p[:pure_text].present?
        # some white line only has white space
        if q[:pure_text].blank? && q[:question_images].blank?
          q = {content: [], pure_text: [], question_images: []}
        end
      end
    end
    parsed_questions
  end

  def is_equation_image?(path)
    begin
      i = Magick::Image.read(path).first
      return i.rows < 30
    rescue
      return false
    end
  end

  def analyze_image_relation
    self.image_relation = {}
    self.image_relation_xml.xpath("//xmlns:Relationship").each do |ele|
      target = ele.attributes["Target"].value
      id = ele.attributes["Id"].value
      next if !target.start_with?("media/image")
      old_name = target.scan(/media\/(.+)/)[0][0]
      new_name = self.image_name_map[old_name]
      name = new_name.blank? ? old_name : new_name
      self.image_relation[id] = "#{self.image_dir}/#{name}"
    end
  end

  def parse_one_question(q)
    puts "*************** one question ******************"
    puts q[:content].join.inspect
    # judge type of this question
    retval = self.judge_question_type(q[:pure_text])
    case retval[0]
    when CHOICE_QS
      return self.parse_choice(q, retval[1])
    when BLANK_QS
      return self.parse_blank(q, retval[1])
    when ANALYSIS_QS
      return self.parse_analysis(q)
    end
  end

  def parse_choice(q, choice_mode)
    parsed_q = { content: "", question_images: [], items: [], image_uuid: self.uuid }
    if choice_mode == ONE_LINE
      q[:content][-1].scan(/A(.+)B(.+)C(.+)D(.*)/)[0].each do |item|
        parsed_q[:items] << { "content" => item.strip }
      end
      parsed_q[:content] = q[:content][0..-2].join('\n')
    elsif choice_mode == TWO_LINE
      q[:content][-2].scan(/A(.+)B(.+)/)[0].each do |item|
        parsed_q[:items] << { "content" => item.strip }
      end
      q[:content][-1].scan(/C(.+)D(.+)/)[0].each do |item|
        parsed_q[:items] << { "content" => item.strip }
      end
      parsed_q[:content] = q[:content][0..-3].join('\n')
    else
      parsed_q[:items] << { "content" => q[:content][-4].scan(/A(.+)/)[0][0].strip }
      parsed_q[:items] << { "content" => q[:content][-3].scan(/B(.+)/)[0][0].strip }
      parsed_q[:items] << { "content" => q[:content][-2].scan(/C(.+)/)[0][0].strip }
      parsed_q[:items] << { "content" => q[:content][-1].scan(/D(.+)/)[0][0].strip }
      parsed_q[:content] = q[:content][0..-5].join('\n')
    end 
    if q[:question_images].length < 4
      parsed_q[:question_images] = q[:question_images]
    elsif
      parsed_q[:question_images] = q[:question_images][0.. -5]
      parsed_q[:items].each_with_index do |item, index|
        image_index = -(index + 1)
        item["images"] = [q[:question_images][image_index]]
      end
    end
    question = Question.create_choice_question(parsed_q, choice_mode)
  end

  def parse_blank(q, blank_number)
    parsed_q = {}
    parsed_q[:question_images] = q[:question_images]
    q[:content].map! do |e|
      e.gsub(/\(\s+\)/, '<blank></blank>').
        gsub(/\[\s+\]/, '<blank></blank>').
        gsub(/_{2,}/, '<blank></blank>')
        # gsub(/\s{2,}/, '<blank></blank>')
    end
    parsed_q[:content] = q[:content].join('\n')
    question = Question.create_blank_question(parsed_q)
  end

  def parse_analysis(q)
    question = Question.create_analysis_question(q)
  end

  def judge_question_type(text)
    # check whether the question type is pointed out in the first line
    if text[0].include?('选择题')
      return [CHOICE_QS, ONE_LINE] if /A.+B.+C.+D.*/.match(text[-1]) # A - D are in one line: A B C D
      return [CHOICE_QS, TWO_LINE] if /A.+B.*/.match(text[-2]) && /C.+D.*/.match(text[-1]) # A - D are in two lines: A B <br /> C D
      return [CHOICE_QS, FOUR_LINE]
    elsif text[0].include?('填空题')
      blanks = text.join.scan(/\(\s+\)/).length
      blanks += text.join.scan(/\[\s+\]/).length
      blanks += text.join.scan(/_+/).length
      return [BLANK_QS, blanks]
    elsif text[0].include?('解答题')
      return [ANALYSIS_QS, nil]
    end
    # check whether "A" - "D" can be found to indicate that this is a choice question
    return [CHOICE_QS, ONE_LINE] if /A.+B.+C.+D.*/.match(text[-1]) # A - D are in one line: A B C D
    return [CHOICE_QS, TWO_LINE] if /A.+B.*/.match(text[-2]) && /C.+D.*/.match(text[-1]) # A - D are in two lines: A B <br /> C D
    return [CHOICE_QS, FOUR_LINE] if /A.*/.match(text[-4]) && /B.*/.match(text[-3]) && /C.*/.match(text[-2]) && /D.*/.match(text[-1]) # A - D are in four lines: A <br /> B <br /> C <br /> D

    parentheses_blanks = text.join.scan(/\(\s+\)/).length
    bracket_blanks = text.join.scan(/\[\s+\]/).length
    underline_blanks = text.join.scan(/_+/).length
    blanks = parentheses_blanks + bracket_blanks + underline_blanks
    return [BLANK_QS, blanks] if blanks > 0

    return [ANALYSIS_QS, nil]
  end
end
