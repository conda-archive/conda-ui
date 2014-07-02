define [
    "jquery"
    "conda_ui/modal"
], ($, Modal) ->

    class DialogView extends Modal.View
        initialize: (options) ->
            @type = options.type
            @message = options.message
            super(options)

        title_text: () -> @type.charAt(0).toUpperCase() + @type.slice(1)

        render_body: () -> $('<span>').text(@message)

        submit_text: () -> null
        cancel_text: () -> "Close"

    return {View: DialogView}
