var $ = require('jquery')
var $Validate = require('validate')

    $.validator.setDefaults({
        highlight: (element) ->
            $(element).closest('.form-group').addClass('has-error')
        unhighlight: (element) ->
            $(element).closest('.form-group').removeClass('has-error')
        errorElement: 'span'
        errorClass: 'help-block validation'
        errorPlacement: (error, element) ->
            if element.parent('.input-group').length
                error.insertAfter(element.parent())
            else
                error.insertAfter(element)
    })

    $.validator.addMethod(
        "regex",
        ((value, element, regexp) ->
            re = new RegExp(regexp)
            this.optional(element) || re.test(value)
        ),
        "Please check your input.",
    )

    $.validator.addMethod(
        "fn",
        ((value, element, fn) ->
            this.optional(element) || fn(value)
        ),
        "Please check your input.",
    )
