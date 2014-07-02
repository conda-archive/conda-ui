define [
    "underscore"
    "jquery"
    "backbone"
], (_, $, Backbone) ->

    class HistoryView extends Backbone.View

        initialize: (options) ->
            super(options)
            @envs = options.envs
            @pkgs = options.pkgs
            @listenTo(@envs, 'all', () => @render())
            @listenTo(@pkgs, 'filter', () => @render())
            @render()

        render: () ->
            env = @envs.get_active()
            if not env? then return

            history = env.get('history')

            if history?
                headers = ['Revision', 'Date', 'Name', 'Removed Version', 'Installed Version']
                $headers = $('<tr>').html($('<th>').text(text) for text in headers)

                mk_version = (version, build) -> $('<td>').text("#{version} (#{build})")
                mk_mdash = () -> $('<td>&mdash;</td>')

                $rows = for history_item in history
                    $revision = $('<td>').text(history_item.revision)
                    $date = $('<td>').text(history_item.date)

                    for diff_item in history_item.diff
                        if @pkgs.do_filter(diff_item.name)
                            continue

                        $name = $('<td>').text(diff_item.name)

                        switch diff_item.op
                            when "install"
                                $new_version = mk_version(diff_item.version, diff_item.build)
                                $old_version = mk_mdash()
                                style = "success"
                                icon = "plus-circle"
                            when "remove"
                                $new_version = mk_mdash()
                                $old_version = mk_version(diff_item.version, diff_item.build)
                                style = "danger"
                                icon = "minus-circle"
                            when "upgrade"
                                $new_version = mk_version(diff_item.new_version, diff_item.new_build)
                                $old_version = mk_version(diff_item.old_version, diff_item.old_build)
                                style = "info"
                                icon = "arrow-circle-up"
                            when "downgrade"
                                $new_version = mk_version(diff_item.new_version, diff_item.new_build)
                                $old_version = mk_version(diff_item.old_version, diff_item.old_build)
                                style = "warning"
                                icon = "arrow-circle-down"

                        $icon = $('<i class="fa">').addClass("fa-#{icon}")
                        $name.prepend([$icon, "&nbsp;"])

                        $columns = [$revision.clone(), $date.clone(), $name, $old_version, $new_version]
                        $('<tr>').html($columns).addClass(style)

                $rows = _.flatten($rows, shallow=true)
                $table = $('<table class="table table-bordered">')
                $table.append($('<thead>').html($headers))
                $table.append($('<tbody>').html($rows))

                @$el.html($table)
            else
                @$el.html("History was not recorded for this environment.")

    return {View: HistoryView}
