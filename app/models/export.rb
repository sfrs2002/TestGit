# encoding: utf-8
require 'fileutils'
require 'zip'
require 'integer'
class Export
  attr_accessor :q_ids_ary, :filename, :main_doc, :rel_doc, :text_ele, :para_ele, :shape_type, :equ_ele, :image_rel, :obj_rel, :first_equation, :rid_index

  def initialize(q_ids_ary)
    # the questions to be exported
    @q_ids_ary = q_ids_ary
    @filename = SecureRandom.uuid
    FileUtils.mkdir "public/downloads/#{@filename}"
    FileUtils.cp_r "lib/blank_doc", "public/downloads/#{@filename}"
    @main_doc = Nokogiri::XML(File.read("public/downloads/#{@filename}/blank_doc/word/document.xml"))
    @rel_doc = Nokogiri::XML(File.read("public/downloads/#{@filename}/blank_doc/word/_rels/document.xml.rels"))
    template_xml = Nokogiri::XML(File.read("lib/template/word/document.xml"))
    @text_ele = template_xml.elements[0].elements[0].elements[0].elements[2].clone
    @shape_type = template_xml.elements[0].elements[0].elements[0].elements[3].elements[1].elements[0].clone
    @equ_ele = template_xml.elements[0].elements[0].elements[0].elements[4].clone
    @para_ele = @main_doc.elements[0].elements[0].elements[0].clone
    template_rel = Nokogiri::XML(File.read("lib/template/word/_rels/document.xml.rels"))
    @image_rel = template_rel.elements[0].elements[7]
    @obj_rel = template_rel.elements[0].elements[6]
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
      if q.type == Question::CHOICE_QS
        q.items.each_with_index do |e, index|
          append_para
          append_text("#{index.to_capital}. ")
          e["content"].split(/(<equation>.*?<\/equation>)/).each do |fragment|
            append_fragment(fragment)
          end
        end
      end
      append_para
    end

    # compress and save as docx file
    filename = generate_docx
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

  # append blank para to the last
  def append_para
    last_para = @main_doc.xpath('.//w:p')[-1]
    last_para.add_next_sibling(@para_ele.clone)
  end

  # append equation w:r to theend of the last paragraph
  def append_equation(image_id)
    image = Image.find(image_id)
    image_file_name = "image#{@rid_index}.wmf"
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
    FileUtils.cp(image.file_name, "public/downloads/#{@filename}/blank_doc/word/embeddings/oleObject#{@rid_index}.bin")
    @rel_doc.at('.//xmlns:Relationships').add_child(obj_rel)
    @rid_index += 1

    last_para = @main_doc.xpath('.//w:p')[-1]
    last_para.add_child(equ_ele)
  end

  # append text w:r to the end of the last paragraph
  def append_text(content)
    temp_text_ele = @text_ele.clone
    temp_text_ele.elements[1].content = content
    last_para = @main_doc.xpath('.//w:p')[-1]
    last_para.add_child(temp_text_ele)
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
