# encoding: utf-8
require 'fileutils'
require 'zip/zip'
require 'RMagick'
class Document
  extend CarrierWave::Mount
  mount_uploader :document, DocumentUploader

  attr_accessor :uuid

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
    image_dir = FileUtils.mkpath("public/temp_images/#{self.uuid}")[0]
    image_filename_ary = []
    # get the xml document and the image files
    xml = nil
    Zip::ZipFile.open(filename) do |zipfile|
      zipfile.each do |entry|
        xml = Nokogiri::XML(entry.get_input_stream.read) if entry.name == "word/document.xml"
        if entry.name.match("word/media/image").present?
          name = entry.name.split('/')[-1]
          File.open("#{image_dir}/#{name}", 'wb') {|file| file.write(entry.get_input_stream.read) }
          if name.end_with?(".wmf")
            i = Magick::Image.read("#{image_dir}/#{name}").first
            old_name = name
            name = name.gsub(".wmf", ".png")
            i = i.write("#{image_dir}/#{name}")
            File.delete("#{image_dir}/#{old_name}")
          end
          image_filename_ary << "#{image_dir}/#{name}"
        end
      end
    end
    image_filename_ary.reverse!
    return nil if xml.nil?

    # parse question
    image_index = 0
    parsed_questions = []
    q = { content: [], pure_text: [], images: [] }
    xml.xpath('//w:body')[0].elements.each do |e|
      # each element here is a paragraph
      contents = e.xpath('.//w:r')
      if contents.blank?
        # this paragraph has no content, the previous might be one question
        parsed_questions << self.parse_one_question(q) if q.present?
        q = {content: [], pure_text: [], images: []}
      else
        # this paragraph has contents
        p = {content: "", pure_text: ""}
        contents.each do |content|
          # the content is text
          if content.xpath('.//w:t').present?
            # should be text
            text = content.xpath('.//w:t')[0]
            p[:content] += text.children[0].text if text.present?
            p[:pure_text] += text.children[0].text if text.present?
          elsif content.xpath('.//w:object').present?
            # should be an equation
            image_filename_ary[image_index]
            p[:content] += "<equation>#{image_filename_ary[image_index]}</equation>"
            p[:pure_text] += "--equation--"
            image_index += 1
          elsif content.xpath('.//w:drawing').present?
            # should be a figure
            q[:images] << image_filename_ary[image_index]
            image_index += 1
          end
        end
        q[:content] << p[:content]
        q[:pure_text] << p[:pure_text] if p[:pure_text].present?
      end
    end
    parsed_questions
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
    parsed_q = { content: "", images: [], items: [], image_uuid: self.uuid }
    if choice_mode == ONE_LINE
      q[:content][-1].scan(/A(.+)B(.+)C(.+)D(.*)/)[0].each do |item|
        parse_q[:items] << { "content" => item.strip }
      end
      parsed_q[:content] = q[:content][0..-2].join('\n')
    elsif choice_mode == TWO_LINE
      q[:content][-2].scan(/A(.+)B(.+)/)[0].each do |item|
        parse_q[:items] << { "content" => item.strip }
      end
      q[:content][-1].scan(/C(.+)D(.+)/)[0].each do |item|
        parse_q[:items] << { "content" => item.strip }
      end
      parsed_q[:content] = q[:content][0..-3].join('\n')
    else
      parsed_q[:items] << { "content" => q[:content][-4].scan(/A(.+)/)[0][0].strip }
      parsed_q[:items] << { "content" => q[:content][-3].scan(/B(.+)/)[0][0].strip }
      parsed_q[:items] << { "content" => q[:content][-2].scan(/C(.+)/)[0][0].strip }
      parsed_q[:items] << { "content" => q[:content][-1].scan(/D(.+)/)[0][0].strip }
      parsed_q[:content] = q[:content][0..-5].join('\n')
    end 
    if q[:images].length < 4
      parsed_q[:images] = q[:images]
    elsif
      parsed_q[:images] = q[:images][0.. -5]
      parsed_q[:items].each_with_index do |item, index|
        image_index = -(index + 1)
        item["images"] = [q[:images][image_index]]
      end
    end
    question = Question.create_choice_question(parsed_q, choice_mode)
  end

  def parse_blank(q, blank_number)
    parsed_q = {}
    parsed_q[:images] = q[:images]
    parsed_q[:content] = q[:content].gsub(/\(\s+\)/, '<blank></blank>').gsub(/\[\s+\]/, '<blank></blank>').gsub(/_+/, '<blank></blank>')
    question = Question.create_blank_question(parsed_q)
  end

  def parse_analysis(q)
    question = Question.create_analysis_question(parsed_q)
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
