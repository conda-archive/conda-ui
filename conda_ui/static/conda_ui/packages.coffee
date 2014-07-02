define [
    "underscore"
    "jquery"
    "backbone"
    "conda_ui/package_modal"

], (_, $, Backbone, PackageModal) ->

    class Package extends Backbone.Model
        defaults: -> {}

    class Packages extends Backbone.Collection
        model: Package
        url: () -> "/api/pkgs"
        parse: (response) -> response.groups

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

    class PackagesView extends Backbone.View

        initialize: (options) ->
            super(options)
            @envs = options.envs
            @pkgs = options.pkgs
            @listenTo(@envs, 'all', () => @render())
            @listenTo(@pkgs, 'all', () => @render())
            @render()

        render: () ->
            env = @envs.get_active()
            if not env? then return

            headers = ['Status', 'Package Name', 'Installed Version', 'Latest Version']
            $headers = $('<tr>').html($('<th>').text(text) for text in headers)

            installed = env.get('installed')

            $rows = for pkg in @pkgs.models
                name = pkg.get('name')
                pkgs = pkg.get('pkgs')

                if @pkgs.do_filter(name)
                    continue

                latest_version = pkgs[pkgs.length-1].version
                installed_version = installed[name]?.version

                $status = $('<td><input type="checkbox"></td>')
                $name = $('<td class="package-name">').text(name).data("package-name", name)
                $installed_version = $('<td>&mdash;</td>')
                $latest_version = $('<td>').text(latest_version)

                if installed_version?
                    $status.find('input').attr(checked: 'checked')
                    $installed_version.text(installed_version)

                $('<tr>').html([$status, $name, $installed_version, $latest_version])

            $table = $('<table class="table table-bordered table-striped">')
            $table.append($('<thead>').html($headers))
            $table.append($('<tbody>').html($rows))
            $table.on("click", ".package-name", @on_name_click)
            @$el.html($table)

        on_name_click: (event) =>
            name = $(event.target).data("package-name")
            pkg = @pkgs.get_by_name(name)
            new PackageModal.View({pkg: pkg, envs: @envs, pkgs: @pkgs}).show()

    return {Model: Package, Collection: Packages, View: PackagesView}
