#= require jquery
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

    $("#upload-input").change (e) -> $("#upload-form").submit()

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
          log "file uploaded"
          $row = $row.replaceWith(ich.tmp_file(
            name: file.name
            path: "/files/#{data.ids[0]}"
          ))
          log $row
          statusCallback = (file) ->
            if file?.progress is "1"
              # TODO: this replaces the whole table
              $row.replaceWith($table.append(ich.tmp_file(blessFile(file))))
            else
              to = setTimeout ->
                clearTimeout(to)
                $.getJSON "/files/#{data.ids[0]}", statusCallback
              , 500
          statusCallback()

        progress: (e) ->
          $progress.removeClass("striped").removeClass("active")
          if e.lengthComputable
            $bar.css("width", ((e.loaded / e.total) * 100)+"%")
