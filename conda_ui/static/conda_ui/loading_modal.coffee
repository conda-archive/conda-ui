$ = require('jquery')
Modal = require('modal')

class LoadingModalView extends Modal.View
    initialize: (options) ->
        @title = options.title
        super(options)

    title_text: () -> @title

    render_body: () ->
        $("<div class=\"progress progress-striped active\">
                <div class=\"progress-bar\" role=\"progressbar\" style=\"width: 100%\">
                </div>
            </div>")

    render_footer: () ->
        # Don't render the buttons in the footer

module.exports.View = LoadingModalView
