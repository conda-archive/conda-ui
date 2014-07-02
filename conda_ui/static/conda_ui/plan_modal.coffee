define [
    "underscore"
    "jquery"
    "conda_ui/utils"
    "conda_ui/modal"
    "conda_ui/dialog"
], (_, $, utils, Modal, Dialog) ->

    class PlanModalView extends Modal.View

        initialize: (options) ->
            @pkg = options.pkg
            @envs = options.envs
            @pkgs = options.pkgs
            @actions = options.actions
            super(options)

        title_text: () -> $('<span>Installation plan for </span>').append($('<span>').text(@pkg.get('name')))

        submit_text: () -> "Proceed"

        render_body: () ->
            fetch = @actions['FETCH']
            unlink = @actions['UNLINK']
            link = @actions['LINK']

            $plan = $('<div>')

            if fetch?
                $description = $('<h5>The following packages will be downloaded:</h5>')

                headers = ['Name', 'Version', 'Build', 'Size']
                $headers = $('<tr>').html($('<th>').text(text) for text in headers)

                $rows = for pkg in fetch
                    info = @pkgs.get_by_dist(pkg.name, pkg.dist)

                    $name = $('<td>').text(pkg.name)
                    $version = $('<td>').text(pkg.version)
                    $build = $('<td>').text(pkg.build)
                    $size = $('<td>').text(utils.human_readable(info.size))

                    $columns = [$name, $version, $build, $size]
                    $('<tr>').html($columns)

                $table = $('<table class="table table-bordered table-striped">')
                $table.append($('<thead>').html($headers))
                $table.append($('<tbody>').html($rows))

                $plan.append([$description, $table])

            if unlink?
                $description = $('<h5>The following packages will be UN-linked:</h5>')

                headers = ['Name', 'Version', 'Build']
                $headers = $('<tr>').html($('<th>').text(text) for text in headers)

                $rows = for pkg in unlink
                    $name = $('<td class="col-plan-name">').text(pkg.name)
                    $version = $('<td class="col-plan-version">').text(pkg.version)
                    $build = $('<td class="col-plan-build">').text(pkg.build)

                    $columns = [$name, $version, $build]
                    $('<tr>').html($columns)

                $table = $('<table class="table table-bordered table-striped unlink">')
                $table.append($('<thead>').html($headers))
                $table.append($('<tbody>').html($rows))

                $plan.append([$description, $table])

            if link?
                $description = $('<h5>The following packages will be linked:</h5>')

                headers = ['Name', 'Version', 'Build']
                $headers = $('<tr>').html($('<th>').text(text) for text in headers)

                $rows = for pkg in link
                    $name = $('<td class="col-plan-name">').text(pkg.name)
                    $version = $('<td class="col-plan-version">').text(pkg.version)
                    $build = $('<td class="col-plan-build">').text(pkg.build)

                    $columns = [$name, $version, $build]
                    $('<tr>').html($columns)

                $table = $('<table class="table table-bordered table-striped">')
                $table.append($('<thead>').html($headers))
                $table.append($('<tbody>').html($rows))

                $plan.append([$description, $table])

            $plan

        on_submit: (event) =>
            env = @envs.get_active()
            api("env/#{env.get('name')}/install", {specs: [@pkg.get('name')]}, @on_install)

        on_install: (data) =>
            if data.ok
                new Dialog.View({type: "info", message: "#{@pkg.get('name')} was successfully installed"}).show()
            else
                new Dialog.View({type: "error", message: data.error}).show()

    return {View: PlanModalView}
