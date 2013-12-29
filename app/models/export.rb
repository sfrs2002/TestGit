# encoding: utf-8
require 'fileutils'
require 'zip'
require 'integer'
class Export
  attr_accessor :q_ids_ary, :filename, :main_doc, :rel_doc, :text_ele, :para_ele, :shape_type, :equ_ele, :image_rel, :obj_rel

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
  end

  def export
    # export questions one by one
    @q_ids_ary.each do |qid|
      q = Question.find(qid)
      append_para
      append_text(q.content)
      if q.type == Question::CHOICE_QS
        q.items.each_with_index do |e, index|
          append_para
          append_text("#{index.to_capital}. #{e["content"]}")
        end
      end
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

  # append equation w:r to theend of the last paragraph
  def append_equation(image_index, object_index, rid_index, first = false)
    
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
