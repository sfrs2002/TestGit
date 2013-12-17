$ ->
  $(".hide").hide()

  $("#delete").click ->
    book_id = $("#book_id").val()
    chapter_id = $("#chapter_id").val()
    section_id = $("#section_id").val()
    subsection_id = $("#subsection_id").val()
    structure_id = subsection_id || section_id || chapter_id || book_id
    return if structure_id == ""
    $.deleteJSON "/admin/structures/" + structure_id, (data) ->
      location.reload();

  $("#book_id").change ->
    if $(this).val() == ""
      clear_children
      return
    $.getJSON "/admin/structures/" + $(this).val() + "/children", (data) ->
      clear_children
      $.each data.data, (i, s) ->
        $("#chapter_id").append($("<option></option>").attr("value", s._id).text(s.name));

  $("#chapter_id").change ->
    if $(this).val() == ""
      clear_children(false)
      return
    $.getJSON "/admin/structures/" + $(this).val() + "/children", (data) ->
      clear_children(false)
      $.each data.data, (i, s) ->
        $("#section_id").append($("<option></option>").attr("value", s._id).text(s.name));

  $("#section_id").change ->
    if $(this).val() == ""
      clear_children(false, false)
      return
    $.getJSON "/admin/structures/" + $(this).val() + "/children", (data) ->
      clear_children(false, false)
      $.each data.data, (i, s) ->
        $("#subsection_id").append($("<option></option>").attr("value", s._id).text(s.name));

  clear_children = (chapter = true, section = true, subsection = true) ->
    $("#chapter_id").find('option').remove().end().append('<option value="">请选择</option>') if chapter
    $("#section_id").find('option').remove().end().append('<option value="">请选择</option>') if section
    $("#subsection_id").find('option').remove().end().append('<option value="">请选择</option>') if subsection
