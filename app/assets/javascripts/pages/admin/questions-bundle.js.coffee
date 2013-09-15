$(->
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
)