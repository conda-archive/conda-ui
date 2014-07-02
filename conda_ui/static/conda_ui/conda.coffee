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
