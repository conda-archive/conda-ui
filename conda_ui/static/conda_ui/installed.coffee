define [
    "underscore"
    "jquery"
    "backbone"
], (_, $, Backbone) ->

    class InstalledView extends Backbone.View

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

            headers = ['Name', 'Version', 'Build', 'Channel', 'Features']
            $headers = $('<tr>').html($('<th>').text(text) for text in headers)

            installed = env.get('installed')

            pkgs = for own name, info of installed
                pkg = @pkgs.get_by_name(name)
                if not pkg? then continue
                _.find(pkg.get('pkgs'), (pkg) -> pkg.dist == info.dist)

            pkgs = _.sortBy(pkgs, (pkg) -> pkg.name)

            $rows = for pkg in pkgs
                if @pkgs.do_filter(pkg.name)
                    continue

                $name = $('<td>').text(pkg.name)
                $version = $('<td>').text(pkg.version)
                $build = $('<td>').text(pkg.build)
                $channel = $('<td>').text(pkg.canonical_channel or pkg.channel).attr(title: pkg.channel)
                $features = $('<td>&mdash;</td>')

                if pkg.features.length > 0
                    $features.text(pkg.features.join(", "))

                $('<tr>').html([$name, $version, $build, $channel, $features])

            $table = $('<table class="table table-bordered table-striped">')
            $table.append($('<thead>').html($headers))
            $table.append($('<tbody>').html($rows))
            @$el.html($table)

    return {View: InstalledView}
