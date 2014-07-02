define [
    "jquery"
    "backbone"
    "bootstrap/modal"
], ($, Backbone, $Modal) ->

    class ModalView extends Backbone.View
        initialize: (options) ->
            super(options)
            @render()

        show: () -> @$el.modal('show')
        hide: () -> @$el.modal('hide')

        toggle: () -> @$el.modal('toggle')

        tagName: 'div'

        render: () ->
            $header = $('<div class="modal-header">').append(@render_header())
            $body = $('<div class="modal-body">').append(@render_body())
            $footer = $('<div class="modal-footer">').append(@render_footer())
            $content = $('<div class="modal-content">').append([$header, $body, $footer])
            size_cls = switch @modal_size()
                when "large" then "modal-lg"
                when "small" then "modal-sm"
                else ""
            $dialog = $('<div class="modal-dialog">').append($content).addClass(size_cls)
            @$el.addClass("modal fade").append($dialog).modal({show: false})
            @$el.on('shown.bs.modal', @on_shown)
            @$el.on('hidden.bs.modal', @on_hidden)
            $('body').append(@$el)

        modal_size: () -> "default"

        title_text: () -> ""

        render_header: () ->
            $close = $('<button type="button" class="close">&times;</button>').click(@on_cancel)
            $title = $('<h4 class="modal-title">').append(@title_text())
            $close.add($title)
        render_body: () -> ""
        render_footer: () ->
            if @submit_text()?
                $submit = $('<button type="submit" class="btn"></button>')
                    .addClass("btn-" + @submit_type()).text(@submit_text()).click(@on_submit)
            else
                $submit = $("")

            if @cancel_text()?
                $cancel = $('<button type="button" class="btn"></button>')
                    .addClass("btn-" + @cancel_type()).text(@cancel_text()).click(@on_cancel)
            else
                $cancel = $("")

            $submit.add($cancel)

        submit_text: () -> "Submit"
        cancel_text: () -> "Cancel"

        submit_type: () -> "primary"
        cancel_type: () -> "default"

        on_submit: (event) =>
        on_cancel: (event) => @hide()

        on_shown: (event) =>
        on_hidden: (event) => @remove()

    return {View: ModalView}
