require.config
    baseUrl: '/static'
    paths:
        jquery: 'jquery-2.1.1/jquery.min'
        validate: 'validate-1.12.0/jquery.validate.min'
        sprintf: 'sprintf-1.0.0/sprintf.min'
        underscore: 'underscore-1.6.0/underscore.min'
        backbone: 'backbone-1.1.2/backbone.min'
        bootstrap: 'bootstrap-3.1.1/js/bootstrap.min'
        condajs: 'conda-js/conda.min'
    shim:
        jquery:
            exports: '$'
        validate:
            deps: ['jquery']
            exports: 'validate'
        sprintf:
            exports: 'sprintf'
        underscore:
            exports: '_'
        backbone:
            deps: ['jquery']
            exports: 'Backbone'
        bootstrap:
            deps: ['jquery']
            exports: 'modal'
        condajs:
            deps: ['jquery']
            exports: 'conda'

define [
    "jquery"
    "conda_ui/envs"
    "conda_ui/search"
    "conda_ui/packages"
    "conda_ui/installed"
    "conda_ui/history"
    "conda_ui/settings"
], ($, Envs, Search, Packages, Installed, History, Settings) ->

    $(document).ready () ->
        envs = new Envs.Collection()
        envs.fetch(reset: true)

        pkgs = new Packages.Collection()
        pkgs.fetch(reset: true)

        new Envs.View({el: $('#envs'), envs: envs})
        new Search.View({el: $('#search'), pkgs: pkgs})
        new Packages.View({el: $('#pkgs'), envs: envs, pkgs: pkgs})
        new Installed.View({el: $('#installed'), envs: envs, pkgs: pkgs})
        new History.View({el: $('#history'), envs: envs, pkgs: pkgs})

        $('#settings').click (event) =>
            new Settings.View().show()
