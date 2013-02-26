#= require jquery
#= require jquery-fileupload/vendor/jquery.ui.widget.js
#= require jquery-fileupload/jquery.iframe-transport
#= require jquery-fileupload/jquery.fileupload

$ ->
  $(".delete-form").submit ->
    confirm("Really delete this file?")

  if $("#upload-input").length
    $("#upload-input").fileupload
      dropZone: $("#dropzone")
      done: -> document.reload()