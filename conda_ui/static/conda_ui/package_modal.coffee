define [
    "underscore"
    "jquery"
    "conda_ui/api"
    "conda_ui/utils"
    "conda_ui/modal"
    "conda_ui/dialog"
    "conda_ui/plan_modal"
], (_, $, api, utils, Modal, Dialog, PlanModal) ->
    version_regex = /(\d)+\.(\d+)((?:\.\d)*)(rc\d+)?/
    parse_version = (version) ->
        matches = version.match version_regex
        parts = [parseInt(matches[1], 10), parseInt(matches[2], 10)]
        extra = matches[3]
        if extra?
            extra = extra.split(/\./g).slice(1)
            parts = parts.concat(extra.map((x) -> parseInt(x, 10)))
        rc = matches[4]
        if rc?
            rc = parseInt(rc.slice(2), 10)

        return {
            parts: parts,
            rc: if rc? then rc else null
        }

    # Is ver2 > ver1
    version_greater = (ver1, ver2) ->
        ver1 = parse_version ver1
        ver2 = parse_version ver2
        for pair in _.zip(ver1.parts, ver2.parts)
            part1 = pair[0]
            part2 = pair[1]

            if not part1? and part2?
                return true
            if part1? and not part2?
                return false

            if part2 > part1
                return true
            if part2 < part1
                return false

        if ver1.rc? and not ver2.rc?
            return true
        if ver2.rc? and not ver1.rc?
            return false
        if ver2.rc? and ver1.rc?
            return ver2.rc > ver1.rc

    # Is pkg2 newer than pkg2
    package_greater = (pkg1, pkg2) ->
        if pkg1.version is pkg2.version
            return pkg2.build_number > pkg1.build_number
        return version_greater(pkg1.version, pkg2.version)

    class PackageModalView extends Modal.View

        initialize: (options) ->
            @pkg = options.pkg
            @envs = options.envs
            @pkgs = options.pkgs

            pkgs = @pkg.get 'pkgs'

            @install = _.all(pkgs, (pkg) -> not pkg.installed)
            @update = false
            if not @install
                installed = _.findWhere pkgs, { installed: true }
                @update = _.any(pkgs, (pkg) -> package_greater(installed, pkg))

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
            @$el.addClass("packages-modal")

        on_update: (event) =>
            @disable_buttons()
            env = @envs.get_active()
            @action = "update"
            env.attributes[@action]({
                dryRun: true,
                packages: [@pkg.get('name')]
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
