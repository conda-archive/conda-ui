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
                info = info.info
                if not info.channel?
                    info.channel = '<no channel>'
                if not info.features?
                    info.features = []
                info

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
