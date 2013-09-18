$(->
  questions = $.parseJSON $("#data").attr("value");
  selected_q_id_arr = []
  $(".hide").hide()

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
)