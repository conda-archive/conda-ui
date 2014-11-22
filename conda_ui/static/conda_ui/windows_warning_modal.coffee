var $ = require('jquery')
var Modal = require("conda_ui/modal")
var utils = require('conda_ui/utils')
var Promise = require("promise")

    class WindowsWarningView extends Modal.View
        initialize: (options) ->
            super(options)
            @promise = new Promise (fulfill, reject) =>
                @fulfill = fulfill
                @reject = reject

        title_text: () -> "Warning"

        render_body: () -> $("<p class=\"alert alert-warning\">Please close any Conda processes, such as IPython, before continuing. Else, the operation may fail.</p>")

        on_submit: (event) =>
            @hide()
            @fulfill()

        @warn_pscheck: () ->
            if utils.on_windows()
                view = new WindowsWarningView()
                view.show()
                return view.promise
            else
                return Promise.resolve(null)

module.exports.warn = WindowsWarningView.warn_pscheck
