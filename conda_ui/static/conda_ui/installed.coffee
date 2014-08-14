define [
    "underscore"
    "jquery"
    "backbone"
    "ractive"
    "conda_ui/api"
    "conda_ui/tab_view"
    "conda_ui/package_modal"
    "conda_ui/package_actions_bar"
    "conda_ui/utils"
], (_, $, Backbone, Ractive, api, TabView, PackageModal, PackageActionsBar, utils) ->

    class InstalledView extends TabView.View

        initialize: (options) ->
            @updates = []

            @ractive = new Ractive({
                template: '#template-package-table',
                data: {
                    pkgs: []
                }
            })
            @ractive.on 'select', @on_check
            @ractive.on 'name-click', @on_name_click

            super(options)

            @listenTo(@pkgs, 'sync', () => @update())
            @listenTo(@envs, 'activate', () => @update())
            @listenTo(@envs, 'sync', () => @update())
            @envs.once('sync', () => @update())

        update: () ->
            env = @envs.get_active()
            if not env? then return

            @updates = []
            for own name, info of env.get('installed')
                record = @pkgs.get_by_name(name)

                if utils.on_windows()
                    if utils.is_windows_ignored(name)
                        # Can't update these on Windows
                        continue

                if record
                    pkgs = record.get('pkgs')
                    try
                        newer = _.filter(pkgs, (pkg) -> api.conda.Package.isGreater(info, pkg))
                    catch e
                        console.log e.stack
                        continue
                    if newer.length > 0
                        if name is 'python'
                            # Don't tell user to update major versions
                            major = info.version.slice(0, 2)
                            if _.any(newer, (pkg) -> pkg.version.slice(0, 2) is major)
                                @updates.push(name)
                        else
                            @updates.push(name)
            @render()

        render: () ->
            env = @envs.get_active()
            if not env? then return

            installed = env.get('installed')

            pkgs = for own name, info of installed
                info = info.info
                if not info.channel?
                    info.channel = '<no channel>'
                if not info.features?
                    info.features = []
                info

            pkgs = _.sortBy(pkgs, (pkg) -> pkg.name)

            data = for pkg in pkgs
                if @pkgs.do_filter(pkg.name)
                    continue

                {
                    name: pkg.name,
                    version: pkg.version,
                    build: pkg.build,
                    channel: pkg.canonical_channel or pkg.channel,
                    features: if pkg.features.length > 0 then pkg.features.join(", ") else "&mdash;",
                    update: @updates.indexOf(pkg.name) > -1
                }

            @ractive.reset { pkgs: data }
            $('#tab-installed').find('.badge').text(data.length)
            if not @ractive.el?
                @ractive.render @el

            @hide_loading()
            @notify_updates()
            PackageActionsBar.instance().hide()

        notify_updates: () ->
            if @updates.length is 0
                @$el.find('.alert').remove()
                return
            if @$el.find('.alert').length
                # Don't re-show alert
                return

            alert = $('<div class="alert alert-info alert-dismissible alert-updates" role="alert">
              <button type="button" class="close" data-dismiss="alert"><span aria-hidden="true">&times;</span><span class="sr-only">Close</span></button>
              <strong>Updates Available</strong> <button type="button" class="btn btn-default pull-right select" data-dismiss="alert">Select Packages</button>
            </div>')
            alert.find('.select').click =>
                @$el.find('input[data-update=update]')
                    .prop('checked', true)
                    .each (i, el) =>
                        @on_check({ node: $(el) })
            @$el.prepend(alert)
            alert.hide().slideDown(500)

        on_name_click: (event) =>
            name = $(event.node).data("package-name")
            pkg = @pkgs.get_by_name(name)
            new PackageModal.View({pkg: pkg, envs: @envs, pkgs: @pkgs}).show()

        on_check: (event) =>
            pkg = $(event.node).parent().next().data('package-name')
            checked = $(event.node).prop('checked')
            PackageActionsBar.instance().setMode('installed')
            PackageActionsBar.instance().on_check(pkg, checked)

        show_loading: ->
            super()
            @$el.find('.alert').remove()

    return {View: InstalledView}
