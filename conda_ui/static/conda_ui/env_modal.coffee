var $ = require("jquery")
var Modal = require("conda_ui/modal")
var Validator = require("conda_ui/validator")
var WindowsWarning = require("conda_ui/windows_warning_modal")

    class EnvModalView extends Modal.View

        initialize: (options) ->
            @envs = options.envs
            @pkgs = options.pkgs
            super(options)

        render_body: () ->
            $label = $('<label>Environment Name</label>')
            @$input = $('<input type="text" class="form-control" name="name" placeholder="Enter name">')
            $help = $('<span class="help-block">Letters, digits and symbols are allowed, but don\'t use slash character.</span>')
            $form_group = $('<div class="form-group">').append([$label, @$input, $help])
            @$form = $('<form role="form">').append($form_group)
            @$form.validate({
                submitHandler: @on_form_submit
                rules: {
                    name: {
                        maxlength: 255
                        required: true
                        regex: /^[^\/]+$/
                        fn: (el) => (name) => not @envs.get_by_name(name)?
                    }
                }
                messages: {
                    name: {
                        regex: "Environment name must not contain slash (/) character."
                        fn: "Environment with this name already exists."
                    }
                }
            })
            @$form

        add_progress: (progress) ->
            if @$form?
                @$form.remove()
            @$progressContainer = $('<div class="progress progress-striped active">')
            @$progress = $('<div class="progress-bar" role="progressbar">')
            @$message = $('<p>')
            @$progressContainer.append(@$progress)
            @$el.find('.modal-body').append(@$message)
            @$el.find('.modal-body').append(@$progressContainer)

            progress.progress (info) =>
                progress = 100 * (info.progress / info.maxval)
                @$progress.css 'width', "#{progress}%"

                if typeof info.fetch isnt "undefined"
                    @$message.text 'Fetching... ' + info.fetch
                else if typeof info.name isnt "undefined"
                    @$message.text 'Linking...' + info.name
                else
                    @$message.text ''

        update_progress: () ->

        on_submit: (event) =>
            if @$form?
                @$form.submit()
            else
                @on_form_submit()

        on_form_submit: (event) =>
            WindowsWarning.warn().then =>
                @doit(@$input?.val())

module.exports.View = EnvModalView
