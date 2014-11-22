var _ = require('underscore')
var $ = require('jquery')
var Backbone = require('backbone')

    class SearchView extends Backbone.View
        initialize: (options) ->
            super(options)
            @pkgs = options.pkgs
            @listenTo(@pkgs, 'filter', @on_filter)
            @render()

        events:
            'keyup input': 'on_keyup'

        tagName: 'div'

        render: () ->
            @$input = $('<input type="text" class="form-control" placeholder="Search packages">')
            $form_group = $('<div class="form-group">').html(@$input)
            @$close = $('<button type="button" class="btn btn-default" disabled="disabled"><span class="close">&times;</span></button>')
            @$close.click(@on_click)
            @$el.html([$form_group, "&nbsp;", @$close])

        on_keyup: (event) =>
            @pkgs.set_filter(@$input.val())

        on_click: (event) =>
            @$input.val("")
            @pkgs.set_filter("")

        on_filter: (filter) =>
            if filter? and filter.length
                @$close.removeAttr("disabled")
            else
                @$close.attr(disabled: "disabled")

module.exports.View = SearchView
