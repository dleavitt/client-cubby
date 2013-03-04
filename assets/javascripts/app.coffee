#= require jquery
#= require jquery-fileupload/vendor/jquery.ui.widget
#= require jquery-fileupload/jquery.iframe-transport
#= require jquery-fileupload/jquery.fileupload
#= require ich

window.log = -> @console?.log?(arguments...)

window.tmpl = (id) -> ich[id]

blessFile = (file) ->
  $.extend
    path: "/files/#{file.id}"
    dlpath: "#{file.path}/download"
    done: file.progress is "1"
    file

$ ->
  $(".delete-form").submit -> confirm "Really delete this file?"

  if $("#upload-form").length || true
    $table = $("#files-table")
    $table.append(ich.tmp_file(blessFile(file))) for file in window.files
    log $("#upload-form")[0]
    $("#upload-input").fileupload
      add: -> log(arguments)
      done: -> log(arguments)
      always: -> log(arguments)
      start: -> log(arguments)
      filesContainer: $table
      dropZone: $("#dropzone")
      uploadTemplateId: "tmp_file"
      downloadTemplateId: "tmp_file"
      uploadTemplate: (o) -> console.log arguments
      downloadTemplate: (o) -> console.log arguments
