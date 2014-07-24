define [
    "underscore"
    "jquery"
    "backbone"
], (_, $, Backbone) ->
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
            @listenTo(@envs, 'request', () => @loading.fadeIn(400))

        showLoading: ->
            @loading.slideDown()

        hideLoading: ->
            @loading.slideUp()

    return { View: TabView }
