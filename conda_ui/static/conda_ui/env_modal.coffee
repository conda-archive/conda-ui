define [
    "jquery"
    "conda_ui/modal"
    "conda_ui/validate"
], ($, Modal, $Validate) ->

    class EnvModalView extends Modal.View

        initialize: (options) ->
            @envs = options.envs
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

        on_submit: (event) =>
            @$form.submit()

        on_form_submit: (event) =>
            @doit(@$input.val())
            @hide()

    return {View: EnvModalView}
