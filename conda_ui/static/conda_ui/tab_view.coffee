var _ = require('underscore')
var $ = require('jquery')
var Backbone = require('backbone')
    class TabView extends Backbone.View
        initialize: (options) ->
            super(options)
            @envs = options.envs
            @pkgs = options.pkgs

            @loading = $('
              <div class="loading container">
                <h3>Loading...</h3>
                <div class="progress progress-striped active">
                  <div class="progress-bar" role="progressbar" style="width: 100%">
                  </div>
                </div>
              </div>').prependTo(@$el)

            @listenTo(@envs, 'sync', () => @render())
            @listenTo(@pkgs, 'sync', () => @render())
            @listenTo(@envs, 'activate', () => @render())
            @listenTo(@pkgs, 'filter', () => @render())
            @listenTo(@envs, 'request', () => @show_loading())

        show_loading: ->
            @loading.slideDown()
            if @ractive?
                @ractive.reset({})

        hide_loading: ->
            @loading.slideUp()

module.exports.View = TabView
