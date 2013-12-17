//= require 'utility/ajax'
$ ->
  $(document).on 'click', '.btn-drop', (e)->
    qid = $(this).data('id')
    $(this).removeClass('btn-danger')
    $(this).removeClass('btn-drop')
    $(this).addClass('btn-keep')
    $(this).text('保留')
    keep_q_ids = $('#keep_q_ids').val().split(',')
    index = keep_q_ids.indexOf(qid)
    if index > -1
      keep_q_ids.splice(index, 1)
    $('#keep_q_ids').val(keep_q_ids.join(','))

  $(document).on 'click', '.btn-keep', (e)->
    qid = $(this).data('id')
    $(this).removeClass('btn-keep')
    $(this).addClass('btn-drop')
    $(this).addClass('btn-danger')
    $(this).text('放弃')
    keep_q_ids = $('#keep_q_ids').val().split(',')
    index = keep_q_ids.indexOf(qid)
    if index == -1
      keep_q_ids.push(qid)
    $('#keep_q_ids').val(keep_q_ids.join(','))



  $(document).on 'click', '#confirm', (e)->
    $.postJSON '/admin/questions/confirm',
      {
        keep_q_ids: window.keep_q_ids,
      }, (data) ->
        if data.success
          alert('ok')
          window.location.href = "/admin/questions"

  $(".hide").hide()
  console.log($("#data"))
  if $("#data").length > 0
    questions = $.parseJSON $("#data").attr("value");
    selected_q_id_arr = []

  $("#question_type_Choice").change (e) ->
    $(".choice").show()
    $(".blank").hide()
    $(".cal").hide()
  $("#question_type_Blank").change (e) ->
    $(".choice").hide()
    $(".blank").show()
    $(".cal").hide()
  $("#question_type_Cal").change (e) ->
    $(".choice").hide()
    $(".blank").hide()
    $(".cal").show()


  $("#add").click ->
    $("#q_list input:checked").each ->
      q_id = $(this).attr("value")
      return if $.inArray(q_id, selected_q_id_arr) != -1
      selected_q_id_arr.push(q_id)
      q = $(this).parent().clone();
      check_box = q.children("input:checked")
      check_box.attr("checked", false)
      $("#selected_q_list").append(q)
      $(this).attr("checked", false)

  $("#remove").click ->
    $("#selected_q_list input:checked").each ->
      q_id = $(this).attr("value")
      $(this).parent().remove()
      selected_q_id_arr = $.grep selected_q_id_arr, (v) ->
        v != q_id

  $("#group").click ->
    $.postJSON '/admin/questions/create_group',
      {
        q_id_arr: selected_q_id_arr,
      }, (data) ->
        if data.success
          $("#selected_q_list").empty()
          selected_q_id_arr = []
        console.log(data);
