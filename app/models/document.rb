# encoding: utf-8
require 'fileutils'
require 'zip'
require 'RMagick'
class Document
  extend CarrierWave::Mount
  mount_uploader :document, DocumentUploader

  attr_accessor :uuid, :main_doc, :rel_doc, :resource_rel, :resource_dir

  def initialize
    @uuid = SecureRandom.uuid
  end

  CHOICE_QS = 0
  BLANK_QS = 1
  ANALYSIS_QS = 2

  ONE_LINE = 0
  TWO_LINE = 1
  FOUR_LINE = 2

  EMU_2_PT = 12700.0

  def parse
    # get the xml document and the resource files
    @resource_dir = FileUtils.mkpath("public/temp_images/#{@uuid}")[0]
    Zip::File.open("public/uploads/documents/#{@uuid}") do |zipfile|
      zipfile.each do |entry|
        @main_doc = Nokogiri::XML(entry.get_input_stream.read) if entry.name == "word/document.xml"
        @rel_doc = Nokogiri::XML(entry.get_input_stream.read) if entry.name == "word/_rels/document.xml.rels"
        if entry.name.match("word/media/image").present? || entry.name.match("word/embeddings/").present?
          name = entry.name.split('/')[-1]
          File.open("#{@resource_dir}/#{name}", 'wb') {|file| file.write(entry.get_input_stream.read) }
        end
      end
    end
    return nil if @main_doc.nil?

    # parse the relation between resource and ids, and save in the @resource_rel
    analyze_resource_rel

    # parse question
    image_index = 0
    parsed_questions = []
    q = { content: [], pure_text: [], question_images: [] }
    @main_doc.at('//w:body').elements.each_with_index do |e, index|
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
            image_rid = object.at('.//v:imagedata').attributes["id"].value
            object_rid = object.at('.//o:OLEObject').attributes["id"].value
            width = object.at('.//v:shape').attributes["style"].value.scan(/width:(.*?)pt/)[0][0]
            height = object.at('.//v:shape').attributes["style"].value.scan(/height:(.*?)pt/)[0][0]
            orig_width = object.attributes["dxaOrig"].value.to_i
            orig_height = object.attributes["dyaOrig"].value.to_i
            image_id = Image.create_object_equation_image(@resource_rel[image_rid],
              @resource_rel[object_rid],
              width,
              height,
              orig_width,
              orig_height)
            p[:content] += "<equation>#{image_id}</equation>"
            p[:pure_text] += "--equation--"
            image_index += 1
          elsif content.xpath('.//w:drawing').present?
            drawing = content.at('.//w:drawing')
            rid = drawing.at('.//a:blip', "a" => "http://schemas.openxmlformats.org/drawingml/2006/main").attributes["embed"].value
            width = drawing.at('.//wp:extent').attributes["cx"].value.to_f / EMU_2_PT
            height = drawing.at('.//wp:extent').attributes["cy"].value.to_f / EMU_2_PT
            # judge whether it is an equation or figure based on the size of the image
            if self.is_equation_image?(@resource_rel[rid])
              # this image is equation
              image_id = Image.create_image_equation_image(@resource_rel[rid], width, height)
              p[:content] += "<equation>#{image_id}</equation>"
              p[:pure_text] += "--equation--"
            else
              # this image is figure
              image_id = Image.create_question_image(@resource_rel[rid], width, height)
              q[:question_images] << image_id
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

  def analyze_resource_rel
    @resource_rel = {}
    @rel_doc.xpath("//xmlns:Relationship").each do |ele|
      target = ele.attributes["Target"].value
      id = ele.attributes["Id"].value
      if target.start_with?("media/image")
        name = target.scan(/media\/(.+)/)[0][0]
        @resource_rel[id] = "#{@resource_dir}/#{name}"
      elsif target.start_with?("embeddings")
        name = target.scan(/embeddings\/(.+)/)[0][0]
        @resource_rel[id] = "#{@resource_dir}/#{name}"
      end
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
    parsed_q = { content: "", question_images: [], items: [], image_uuid: @uuid }
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
