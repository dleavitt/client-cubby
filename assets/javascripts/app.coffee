#= require jquery
#  require jquery-fileupload/vendor/jquery.ui.widget
#  require jquery-fileupload/jquery.iframe-transport
#  require jquery-fileupload/jquery.fileupload
#= require jquery.ajax.progress
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

  if $("#upload-form").length
    $table = $("#files-table")
    $table.append(ich.tmp_file(blessFile(file))) for file in window.files

    $("#upload-form").submit (e) ->
      e.preventDefault()

      $input = $("#upload-input")

      file = $input[0].files[0]
      formData = new FormData()
      formData.append('files[]', file)
      formData.append('_csrf', $("meta[name=_csrf]").attr("content"))

      $table.prepend(ich.tmp_file(name: file.name))

      $row      = $table.find("tr:first")
      $progress = $row.find(".progress")
      $bar      = $progress.find(".bar")

      $.ajax
        url: @getAttribute("action")
        data: formData
        cache: false
        contentType: false
        processData: false
        type: 'POST'
        success: (data) ->
          $row.replaceWith(ich.tmp_file(
            name: file.name
            path: "/files/#{data.ids[0]}"
          ))
        progress: (e) ->
          $progress.removeClass("striped").removeClass("active")
          if e.lengthComputable
            $bar.css("width", ((e.loaded / e.total) * 100)+"%")

    # $("#upload-input").fileupload
    #   add: -> log(arguments)
    #   done: -> log(arguments)
    #   always: -> log(arguments)
    #   start: -> log(arguments)
    #   filesContainer: $table
    #   dropZone: $("#dropzone")
    #   uploadTemplateId: "tmp_file"
    #   downloadTemplateId: "tmp_file"
    #   uploadTemplate: (o) -> console.log arguments
    #   downloadTemplate: (o) -> console.log arguments
