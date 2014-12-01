_ = require('underscore')
$ = require('jquery')
Backbone = require('backbone')
Dialog = require('dialog')
LoadingModal = require('loading_modal')
PlanModal = require('loading_modal')
LoadingModal = require('loading_modal')
TabView = require('tab_view')
conda = require('condajs')

class HistoryView extends TabView.View

    initialize: (options) ->
        @ractive = new Ractive({
            template: '#template-history-table',
            data: {
                history: []
            }
        })
        @ractive.on 'revert', @revert
        super(options)

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
            if not @ractive.el?
                @ractive.render @el
            @loading.hide()
        else
            @$el.html("History was not recorded for this environment.")

    revert: (event) =>
        revision = event.context.revision
        loading = new LoadingModal.View({ title: "Generating plan..." })
        loading.show()
        promise = @envs.get_active().attributes.install({
            dryRun: true,
            revision: revision
        })
        promise.then (data) =>
            loading.hide()
            if data.success? and data.success
                if data.message?
                    new Dialog.View({ message: data.message, type: "Message" }).show()
                else
                    new PlanModal.View({
                        envs: @envs,
                        pkgs: @pkgs,
                        actions: data.actions,
                        action: 'revert',
                        revision: revision
                    }).show()
            else
                new Dialog.View({ message: data.error, type: "Error" }).show()

module.exports.View = HistoryView
