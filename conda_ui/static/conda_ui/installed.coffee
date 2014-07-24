define [
    "underscore"
    "jquery"
    "backbone"
    "ractive"
    "conda_ui/tab_view"
    "conda_ui/package_actions_bar"
], (_, $, Backbone, Ractive, TabView, PackageActionsBar) ->

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

            super(options)

            @listenTo(@envs, 'activate', () => @update())
            @envs.once 'sync', () => @update()

        update: () ->
            env = @envs.get_active()
            if not env? then return
            console.log "Checking for updates"
            # Have conda figure out what needs updating
            env.attributes.update({
                dryRun: true
                useLocal: true
                all: true
            }).then (data) =>
                if data.success? and data.success
                    updates = data.actions.LINK
                    @updates = updates.map (cmd) ->
                        pkg = cmd.split(" ")[0]
                        parts = pkg.split(/-/g)
                        return parts.slice(0, -2).join('-')
                else
                    @updates = []

                @render()
                @notify_updates()

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

            @installed = for pkg in pkgs
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

            @ractive.reset { pkgs: @installed }
            $('#tab-installed').find('.badge').text(@installed.length)
            if not @ractive.el?
                @ractive.render @el

            @hideLoading()
            @$el.find('.alert').remove()
            PackageActionsBar.instance().hide()

        notify_updates: () ->
            @$el.find('.alert').remove()
            if @updates.length is 0 then return

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

        on_check: (event) =>
            pkg = $(event.node).parent().next().data('package-name')
            checked = $(event.node).prop('checked')
            PackageActionsBar.instance().setMode('installed')
            PackageActionsBar.instance().on_check(pkg, checked)

    return {View: InstalledView}
