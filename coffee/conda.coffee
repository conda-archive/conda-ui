$(document).ready () ->
    $("#search").keyup (event) ->
        search = $(event.target).val()
        $rows = $("#names").children("tr")

        if search.length == 0
            $rows.removeClass("hidden")
        else
            $rows.each (index, el) ->
                $el = $(el)
                if $el.data("conda-name").indexOf(search) == -1
                    $el.addClass("hidden")
                else
                    $el.removeClass("hidden")
