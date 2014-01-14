//= require 'utility/ajax'
$ ->
  start_edit_name = ->
    $(".group-name-edit").show()
    $(".group-name-preview").hide()

  $(".group-name-edit").hide()
  $(".group-name").click((e) ->
    e.stopPropagation()
  ).dblclick ->
    $(this).find(".group-name-edit").show()
    $(this).find(".group-name-preview").hide()
    $(this).find(".group_name").focus()

  $(".ok").click (e) ->
    console.log("click ok")
    $this = $(this)
    group_name = $(this).parent().find(".group_name").val()
    $.postJSON(
      '/admin/groups/' + $(this).data("group-id") + '/update_name.json',
      { name: group_name },
      (retval) ->
        $this.parent().parent().find(".group-name-edit").hide()
        $this.parent().parent().find(".group-name-preview").html(group_name)
        $this.parent().parent().find(".group-name-preview").show()
    ) 

  $(".cancel").click (e) ->
    $(this).parent().parent().find(".group-name-edit").hide()
    $(this).parent().parent().find(".group-name-preview").show()
