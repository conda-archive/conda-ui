require.config
    baseUrl: '/static'
    paths:
        jquery: 'jquery-2.1.1/jquery.min'
        validate: 'validate-1.12.0/jquery.validate.min'
        sprintf: 'sprintf-1.0.0/sprintf.min'
        underscore: 'underscore-1.6.0/underscore.min'
        backbone: 'backbone-1.1.2/backbone.min'
        bootstrap: 'bootstrap-3.1.1/js/bootstrap.min'
        bootstrap_tagsinput: 'bootstrap-tagsinput-0.3.9/js/bootstrap-tagsinput.min'
        ractive: 'ractivejs-0.5.5/ractive'
        promise: 'promise-4.0.0/promise'
        sockjs: 'sockjs-0.3/sockjs'
        condajs: 'conda-js/conda'
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
        bootstrap_tagsinput:
            deps: ['jquery', 'bootstrap']
            exports: '$'
        ractive:
            exports: 'Ractive'
        promise:
            exports: 'Promise'
        sockjs:
            exports: ['SockJS']
        condajs:
            deps: ['jquery', 'promise', 'sockjs']
            exports: 'conda'

define [
    "jquery"
    "conda_ui/envs"
    "conda_ui/search"
    "conda_ui/packages"
    "conda_ui/installed"
    "conda_ui/history"
    "conda_ui/settings"
    "conda_ui/package_actions_bar"
], ($, Envs, Search, Packages, Installed, History, Settings, PackageActionsBar) ->

    $(document).ready () ->
        envs = new Envs.Collection()
        envs.fetch(reset: true)

        pkgs = new Packages.Collection()
        pkgs.fetch(reset: true)

        PackageActionsBar.instance($('#package-actions'), envs, pkgs)

        new Envs.View({el: $('#envs'), envs: envs, pkgs: pkgs})
        new Search.View({el: $('#search'), pkgs: pkgs})
        new Packages.View({el: $('#pkgs'), envs: envs, pkgs: pkgs})
        new Installed.View({el: $('#installed'), envs: envs, pkgs: pkgs})
        new History.View({el: $('#history'), envs: envs, pkgs: pkgs})

        $('#settings').click (event) =>
            new Settings.View({ envs: envs, pkgs: pkgs })
