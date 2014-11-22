_ = require('underscore')
$ = require('jquery')
api = require('conda_ui/api')
utils = require('conda_ui/utils')
Modal = require('conda_ui/modal')
Dialog = require('conda_ui/dialog')
PlanModal = require('conda_ui/plan_modal')

class PackageModalView extends Modal.View

    initialize: (options) ->
        @pkg = options.pkg
        @envs = options.envs
        @pkgs = options.pkgs

        pkgs = @pkg.get 'pkgs'
        env = @envs.get_active()

        @install = typeof env.get('installed')[@pkg.get('name')] is "undefined"
        @update = false
        if not @install
            installed = env.get('installed')[@pkg.get('name')]
            if utils.on_windows() and utils.is_windows_ignored(@pkg.get('name'))
                @update = false
            else
                @update = _.any(pkgs, (pkg) -> api.conda.Package.isGreater(installed, pkg))

        super(options)

    modal_size: () -> "large"

    title_text: () -> @pkg.get('name')

    submit_text: () ->
        switch
            when @install then "Install Latest"
            else "Uninstall Installed"

    submit_type: () ->
        switch
            when @install then super()
            else "danger"

    render_body: () ->
        headers = ['', 'Name', 'Version', 'Build', 'Size', 'Channel', 'Features']
        $headers = $('<tr>').html($('<th>').text(text) for text in headers)

        $rows = for pkg in @pkg.get('pkgs')
            $select = $("<input type=\"radio\" name=\"#{pkg.name}\" />")
            $name = $('<td>').text(pkg.name)
            $version = $('<td>').text(pkg.version)
            $build = $('<td>').text(pkg.build)
            $size = $('<td>').text(utils.human_readable(pkg.size))
            $channel = $('<td>').text(pkg.canonical_channel or pkg.channel).attr(title: pkg.channel)
            $features = $('<td>&mdash;</td>')

            if pkg.features.length > 0
                $features.text(pkg.features.join(", "))

            env = @envs.get_active()
            info = env?.get('installed')[pkg.name]
            style = if info?.version == pkg.version and info?.build == pkg.build then "success" else ""

            if style is "success"
                $select = $('<td>')
            else
                $select.change =>
                    @$downgrade.fadeIn()
                $select.data
                    version: pkg.version
                    build: pkg.build
                $select = $('<td>').append($select)

            $columns = [$select, $name, $version, $build, $size, $channel, $features]
            $('<tr>').html($columns).addClass(style)

        $table = $('<table class="table table-bordered table-striped">')
        $table.append($('<thead>').html($headers))
        $table.append($('<tbody>').html($rows))
        $table

    render_footer: () ->
        $footer = super()
        @$downgrade = $('<button type="submit" class="btn"></button>')
            .addClass("btn-warning").text("Install Selected").click(@on_downgrade).hide()
        if @update
            $update = $('<button type="submit" class="btn"></button>')
                .addClass("btn-info").text("Update Installed").click(@on_update)
        [@$downgrade, $update, $footer[0], $footer[1]]

    render: () ->
        super()
        @$el.addClass("scrollable-modal")

    on_update: (event) =>
        @disable_buttons()
        env = @envs.get_active()
        @action = "update"
        env.attributes[@action]({
            dryRun: true,
            packages: [@pkg.get('name')],
            forcePscheck: true
        }).then @on_plan

    on_submit: (event) =>
        @disable_buttons()
        env = @envs.get_active()
        @action = switch
            when @install then "install"
            else "remove"
        env.attributes[@action]({
            dryRun: true,
            packages: [@pkg.get('name')]
            forcePscheck: true
        }).then @on_plan

    on_downgrade: (event) =>
        @disable_buttons()
        env = @envs.get_active()
        @action = "install"
        radio = @$('input[type=radio]:checked')
        version = radio.data('version')
        build = radio.data('build')
        @pkg = ["#{@pkg.get('name')}=#{version}=#{build}"]
        env.attributes[@action]({
            dryRun: true,
            packages: @pkg
            forcePscheck: true
        }).then @on_plan

    on_plan: (data) =>
        @enable_buttons()
        if data.success? and data.success
            if data.message?
                new Dialog.View({ message: data.message, type: "Message" }).show()
            else
                @hide()
                new PlanModal.View({
                    pkg: @pkg,
                    envs: @envs,
                    pkgs: @pkgs,
                    actions: data.actions,
                    action: @action
                }).show()
        else
            new Dialog.View({ message: data.error, type: "Error" }).show()

module.exports.View = PackageModalView
