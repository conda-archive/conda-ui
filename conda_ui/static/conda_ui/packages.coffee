var _ = require('underscore')
var $ = require('jquery')
var Ractive = require('ractive')
var Backbone = require('backbone')
var TabView = require('conda_ui/tab_view')
var PackageModal = require('conda_ui/package_modal')
var PackageActionsBar = require('conda_ui/package_actions_bar')

class Package extends Backbone.Model
    defaults: -> {}

class Packages extends Backbone.Collection
    model: Package
    firstLoad: true

    sync: (method, model, options) ->
        if method is "read"
            conda.index({ reload: not @firstLoad }).then (data) ->
                restructured = for own key, pkgs of data
                    pkgs = for pkg in pkgs
                        pkg.dist = pkg.fn.slice(0, -8)
                        pkg
                    {
                        name: key
                        pkgs: pkgs
                    }
                options.success restructured
            @firstLoad = false
        else
            console.log method

    get_by_name: (name) ->
        _.find(@models, (pkg) -> pkg.get('name') == name)

    get_by_dist: (name, dist) ->
        pkg = @get_by_name(name)
        if pkg?
            _.find(pkg.get('pkgs'), (pkg) -> pkg.dist == dist)
        else
            null

    get_filter: () ->
        @_filter

    set_filter: (filter) ->
        @_filter = filter
        @trigger("filter", @_filter)

    do_filter: (name) ->
        @_filter? and @_filter.length != 0 and name.indexOf(@_filter) == -1

class PackagesView extends TabView.View

    initialize: (options) ->
        @ractive = new Ractive({
            template: '#template-package-table',
            data: {
                pkgs: []
            }
        })
        @ractive.on 'select', @on_check
        @ractive.on 'name-click', @on_name_click
        super(options)

    render: () ->
        env = @envs.get_active()
        if not env? then return

        installed = env.get('installed')

        data = for pkg in @pkgs.models
            name = pkg.get('name')
            pkgs = pkg.get('pkgs')

            if @pkgs.do_filter(name)
                continue
            if installed[name]?.version
                continue

            pkg = pkgs[pkgs.length-1]
            {
                name: name,
                version: pkg.version,
                build: pkg.build,
                channel: pkg.canonical_channel or pkg.channel or '<no channel>',
                features: if pkg.features.length > 0 then pkg.features.join(", ") else "&mdash;"
            }

        @ractive.reset { pkgs: data }
        $('#tab-pkgs').find('.badge').text(data.length)
        if not @ractive.el?
            @ractive.render @el
        @hide_loading()

    on_name_click: (event) =>
        name = $(event.node).data("package-name")
        pkg = @pkgs.get_by_name(name)
        new PackageModal.View({pkg: pkg, envs: @envs, pkgs: @pkgs}).show()

    on_check: (event) =>
        pkg = $(event.node).parent().next().data('package-name')
        checked = $(event.node).prop('checked')
        PackageActionsBar.instance().setMode('available')
        PackageActionsBar.instance().on_check(pkg, checked)

module.exports.Model = Package
module.exports.Collection = Packages
module.exports.View = PackagesView
