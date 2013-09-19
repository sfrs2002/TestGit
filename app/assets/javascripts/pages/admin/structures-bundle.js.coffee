$ ->
  $(".hide").hide()

  $("#delete").click ->
    book_id = $("#books").val()
    chapter_id = $("#chapters").val()
    section_id = $("#sections").val()
    subsection_id = $("#subsections").val()
    structure_id = subsection_id || section_id || chapter_id || book_id
    return if structure_id == ""
    $.deleteJSON "/admin/structures/" + structure_id, (data) ->
      location.reload();

  $("#books").change ->
    set_parent()
    if $(this).val() == ""
      clear_children
      return
    $.getJSON "/admin/structures/" + $(this).val() + "/children", (data) ->
      clear_children
      $.each data.data, (i, s) ->
        $("#chapters").append($("<option></option>").attr("value", s._id).text(s.name));

  $("#chapters").change ->
    set_parent()
    if $(this).val() == ""
      clear_children(false)
      return
    $.getJSON "/admin/structures/" + $(this).val() + "/children", (data) ->
      $("#sections").find('option').remove().end().append('<option value="">请选择</option>')
      $("#subsections").find('option').remove().end().append('<option value="">请选择</option>')
      $.each data.data, (i, s) ->
        $("#sections").append($("<option></option>").attr("value", s._id).text(s.name));

  $("#sections").change ->
    set_parent()
    if $(this).val() == ""
      clear_children(false, false)
      return
    $.getJSON "/admin/structures/" + $(this).val() + "/children", (data) ->
      $("#subsections").find('option').remove().end().append('<option value="">请选择</option>')
      $.each data.data, (i, s) ->
        $("#subsections").append($("<option></option>").attr("value", s._id).text(s.name));

  set_parent = ->
    $("#book_id").val($("#books").val())
    $("#chapter_id").val($("#chapters").val())
    $("#section_id").val($("#sections").val())

  clear_children = (chapter = true, section = true, subsection = true) ->
    $("#chapters").find('option').remove().end().append('<option value="">请选择</option>') if chapter
    $("#sections").find('option').remove().end().append('<option value="">请选择</option>') if section
    $("#subsections").find('option').remove().end().append('<option value="">请选择</option>') if subsection
