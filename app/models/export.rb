# encoding: utf-8
require 'fileutils'
require 'zip'
require 'integer'
class Export
  attr_accessor :q_ids_ary, :filename, :main_doc, :rel_doc
  attr_accessor :text_ele, :para_ele, :shape_type, :equ_ele, :image_ele, :image_rel, :obj_rel
  attr_accessor :first_equation, :rid_index

  def initialize(q_ids_ary)
    # the questions to be exported
    @q_ids_ary = q_ids_ary
    @filename = SecureRandom.uuid
    FileUtils.mkdir "public/downloads/#{@filename}"
    FileUtils.cp_r "lib/blank_doc", "public/downloads/#{@filename}"
    @main_doc = Nokogiri::XML(File.read("public/downloads/#{@filename}/blank_doc/word/document.xml"))
    @rel_doc = Nokogiri::XML(File.read("public/downloads/#{@filename}/blank_doc/word/_rels/document.xml.rels"))
    template_xml = Nokogiri::XML(File.read("lib/template/word/document.xml"))
    @text_ele = template_xml.at('.//w:t').parent.clone
    @shape_type = template_xml.at('.//v:shapetype').clone
    @equ_ele = template_xml.xpath('.//w:object')[1].parent.clone
    @image_ele = template_xml.at('.//w:pict').parent.clone
    @para_ele = @main_doc.at('.//w:p').clone
    template_rel = Nokogiri::XML(File.read("lib/template/word/_rels/document.xml.rels"))
    template_rel.at('//xmlns:Relationships').elements.each do |relation_ship|
      if relation_ship.attributes["Type"].value.end_with?("oleObject")
        @obj_rel = relation_ship
      end
      if relation_ship.attributes["Type"].value.end_with?("image")
        @image_rel = relation_ship
      end
    end
    @first_equation = true
    @rid_index = 7
  end

  def export
    # export questions one by one
    @q_ids_ary.each do |qid|
      q = Question.find(qid)
      append_para
      q.content.gsub("<blank></blank>", "_____").split(/(<equation>.*?<\/equation>)/).each do |fragment|
        append_fragment(fragment)
      end
      if q.question_images.present?
        append_para
        q.question_images.each do |image|
          append_image(image.id)
        end
      end
      if q.type == Question::CHOICE_QS
        q.items.each_with_index do |e, index|
          append_para
          append_text("#{index.to_capital}. ")
          e["content"].split(/(<equation>.*?<\/equation>)/).each do |fragment|
            append_fragment(fragment)
          end
        end
      end
      append_qrcode(qid)
      append_para
    end
    # compress and save as docx file
    filename = generate_docx
  end

  # append blank para to the last
  def append_para
    last_para = @main_doc.xpath('.//w:p')[-1]
    last_para.add_next_sibling(@para_ele.clone)
  end

  def append_fragment(fragment)
    if fragment.start_with?('<equation>')
      image_id = fragment.scan(/<equation>(.*)<\/equation>/)[0][0]
      append_equation(image_id)
      @rid_index += 1
    else
      rows = fragment.split("\\n")
      rows[0..-2].each do |row|
        append_text(row)
        append_para
      end
      append_text(rows[-1])
    end
  end

  # append equation w:r to the end of the last paragraph
  def append_equation(image_id)
    image = Image.find(image_id)
    if image.type == Image::MATH_EQUATION
      append_mathtype(image)
    else
      append_image(image)
    end
  end

  # append mathtype equation w:r to the end of the last paragraph
  def append_mathtype(image)
    obj_file_name = "oleObject#{@rid_index}.bin"
    equ_ele = @equ_ele.clone
    if @first_equation
      @first_equation = false
      shape_type = @shape_type.clone
      equ_ele.at('.//v:shape').add_previous_sibling(shape_type)
    end
    equ_ele.at(".//v:shape").attributes["style"].value = "width:#{image.width}pt;height:#{image.height}pt"
    equ_ele.at(".//v:imagedata").attributes["id"].value = "rId#{@rid_index}"
    image_rel = @image_rel.clone
    image_rel.attributes["Id"].value = "rId#{@rid_index}"
    image_rel.attributes["Target"].value = "media/image#{@rid_index}.wmf"
    FileUtils.cp(image.file_name, "public/downloads/#{@filename}/blank_doc/word/media/image#{@rid_index}.wmf")
    @rel_doc.at('.//xmlns:Relationships').add_child(image_rel)
    @rid_index += 1

    equ_ele.at(".//o:OLEObject").attributes["id"].value = "rId#{@rid_index}"
    obj_rel = @obj_rel.clone
    obj_rel.attributes["Id"].value = "rId#{@rid_index}"
    obj_rel.attributes["Target"].value = "embeddings/oleObject#{@rid_index}.bin"
    FileUtils.cp(image.obj_file_name, "public/downloads/#{@filename}/blank_doc/word/embeddings/oleObject#{@rid_index}.bin")
    @rel_doc.at('.//xmlns:Relationships').add_child(obj_rel)
    @rid_index += 1

    equ_ele.at(".//w:object").attributes["dxaOrig"].value = image.orig_width.to_s
    equ_ele.at(".//w:object").attributes["dyaOrig"].value = image.orig_height.to_s

    shape_id = SecureRandom.uuid
    equ_ele.at(".//v:shape").attributes["id"].value = shape_id
    equ_ele.at(".//o:OLEObject").attributes["ShapeID"].value = shape_id

    last_para = @main_doc.xpath('.//w:p')[-1]
    last_para.add_child(equ_ele)
  end

  # append image w:r to the end of the last paragraph
  def append_image(image)
    image_ele = @image_ele.clone
    image_ele.at(".//v:shape").attributes["style"].value = "width:#{image.width}pt;height:#{image.height}pt"
    image_ele.at(".//v:imagedata").attributes["id"].value = "rId#{@rid_index}"
    image_rel = @image_rel.clone
    image_rel.attributes["Id"].value = "rId#{@rid_index}"
    image_rel.attributes["Target"].value = "media/image#{@rid_index}.#{image.file_type}"
    FileUtils.cp(image.file_name, "public/downloads/#{@filename}/blank_doc/word/media/image#{@rid_index}.#{image.file_type}")
    @rel_doc.at('.//xmlns:Relationships').add_child(image_rel)
    @rid_index += 1

    last_para = @main_doc.xpath('.//w:p')[-1]
    last_para.add_child(image_ele)
  end

  # append text w:r to the end of the last paragraph
  def append_text(content)
    temp_text_ele = @text_ele.clone
    temp_text_ele.elements[1].content = content
    last_para = @main_doc.xpath('.//w:p')[-1]
    last_para.add_child(temp_text_ele)
  end

  def append_qrcode(question_id)
    q = Question.find(question_id)
    append_para
    image_ele = @image_ele.clone
    image_ele.at(".//v:shape").attributes["style"].value = "width:50pt;height:50pt;visibility:visible;mso-wrap-style:square"
    image_ele.at(".//v:imagedata").attributes["id"].value = "rId#{@rid_index}"
    image_rel = @image_rel.clone
    image_rel.attributes["Id"].value = "rId#{@rid_index}"
    image_rel.attributes["Target"].value = "media/image#{@rid_index}.png"
    FileUtils.cp("public/question_images/#{q.id.to_s}/#{q.id.to_s}.png", "public/downloads/#{@filename}/blank_doc/word/media/image#{@rid_index}.png")
    @rel_doc.at('.//xmlns:Relationships').add_child(image_rel)
    @rid_index += 1

    last_para = @main_doc.xpath('.//w:p')[-1]
    last_para.add_child(image_ele)
  end

  def generate_docx
    File.open("public/downloads/#{@filename}/blank_doc/word/document.xml",'w') {|f| f.print @main_doc.to_xml}
    File.open("public/downloads/#{@filename}/blank_doc/word/_rels/document.xml.rels",'w') {|f| f.print @rel_doc.to_xml}
    # zip and rename as docx file
    directory = "public/downloads/#{@filename}/blank_doc"
    zipfile_name = "public/downloads/#{@filename}.zip"
    Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
      Dir.glob(File.join(directory, '**', '**'), File::FNM_DOTMATCH).each do |file|
        next if file.end_with?('.')
        puts file
        zipfile.add(file.sub(directory, '')[1..-1], file)
      end
    end
    File.rename(zipfile_name, zipfile_name.gsub('zip', 'docx'))
    zipfile_name.gsub('zip', 'docx')
  end
end
