define [
    "underscore"
    "jquery"
    "backbone",
    "condajs"
], (_, $, Backbone, conda) ->

    class HistoryView extends Backbone.View

        initialize: (options) ->
            super(options)
            @envs = options.envs
            @pkgs = options.pkgs

            @ractive = new Ractive({
                el: @el,
                template: '#template-history-table',
                data: {
                    history: []
                }
            })
            @listenTo(@envs, 'all', () => @render())
            @listenTo(@pkgs, 'filter', () => @render())

        render: () ->
            env = @envs.get_active()
            if not env? then return

            history = env.get('history')

            if history?
                mk_version = (version, build) -> "#{version} (#{build})"

                @history = []
                for history_item in history
                    for op in ["install", "remove", "upgrade", "downgrade"]
                        for diff_item in history_item[op]
                            if @pkgs.do_filter(if typeof diff_item is "object" then diff_item.new else diff_item)
                                continue

                            switch op
                                when "install"
                                    diff_item = conda.Package.splitFn(diff_item)
                                    new_version = mk_version(diff_item.version, diff_item.build)
                                    old_version = "&mdash;"
                                    style = "success"
                                    icon = "plus-circle"
                                when "remove"
                                    diff_item = conda.Package.splitFn(diff_item)
                                    new_version = "&mdash;"
                                    old_version = mk_version(diff_item.version, diff_item.build)
                                    style = "danger"
                                    icon = "minus-circle"
                                when "upgrade"
                                    old_item = conda.Package.splitFn(diff_item.old)
                                    diff_item = conda.Package.splitFn(diff_item.new)
                                    new_version = mk_version(diff_item.version, diff_item.build)
                                    old_version = mk_version(old_item.version, old_item.build)
                                    style = "info"
                                    icon = "arrow-circle-up"
                                when "downgrade"
                                    old_item = conda.Package.splitFn(diff_item.old)
                                    diff_item = conda.Package.splitFn(diff_item.new)
                                    new_version = mk_version(diff_item.version, diff_item.build)
                                    old_version = mk_version(old_item.version, old_item.build)
                                    style = "warning"
                                    icon = "arrow-circle-down"

                            @history.push {
                                revision: history_item.rev
                                date: history_item.date
                                name: diff_item.name
                                icon: icon
                                style: style
                                old_version: old_version,
                                new_version: new_version
                            }

                @ractive.reset { history: @history }
            else
                @$el.html("History was not recorded for this environment.")

    return {View: HistoryView}
