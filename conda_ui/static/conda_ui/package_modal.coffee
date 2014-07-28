define [
    "underscore"
    "jquery"
    "conda_ui/api"
    "conda_ui/utils"
    "conda_ui/modal"
    "conda_ui/dialog"
    "conda_ui/plan_modal"
], (_, $, api, utils, Modal, Dialog, PlanModal) ->
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
                when @install then "Install"
                else "Uninstall"

        submit_type: () ->
            switch
                when @install then super()
                else "danger"

        render_body: () ->
            headers = ['Name', 'Version', 'Build', 'Size', 'Channel', 'Features']
            $headers = $('<tr>').html($('<th>').text(text) for text in headers)

            $rows = for pkg in @pkg.get('pkgs')
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

                $columns = [$name, $version, $build, $size, $channel, $features]
                $('<tr>').html($columns).addClass(style)

            $table = $('<table class="table table-bordered table-striped">')
            $table.append($('<thead>').html($headers))
            $table.append($('<tbody>').html($rows))
            $table

        render_footer: () ->
            $footer = super()
            if @update
                $update = $('<button type="submit" class="btn"></button>')
                    .addClass("btn-info").text("Update").click(@on_update)
            [$footer[0], $update, $footer[1]]

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

    return {View: PackageModalView}
