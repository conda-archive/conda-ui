_ = require('underscore')
$ = require('jquery')
Backbone = require('backbone')
Dialog = require('dialog')
PlanModal = require('plan_modal')
LoadingModal = require('loading_modal')


class PackageActionsBar extends Backbone.View
    events:
        "click .install": "on_install"
        "click .update": "on_update"
        "click .uninstall": "on_uninstall"
        "click .uncheck-all": "on_uncheck_all"

    initialize: (options) ->
        @envs = options.envs
        @pkgs = options.pkgs

        @checked = {}
        @visible = false

        @setMode 'installed' # or 'available'

        @render()

    setMode: (mode) ->
        @mode = mode

        @$('.btn').show()
        if @mode is 'installed'
            @$('.install').hide()
        else
            @$('.uninstall,.update').hide()

    render: ->
        $('a[data-toggle="tab"]').on 'show.bs.tab', =>
            @hide()

    on_check: (pkg, checked) =>
        if checked
            @checked[pkg] = true
        else if @checked[pkg]?
            delete @checked[pkg]

        @$el.find('.number-checked').html(_.size(@checked))
        @$el.find('.checked-names').html(_.keys(@checked).sort().join(', '))

        if not @visible
            @visible = true
            @$el.show()
        if _.size(@checked) is 0
            @hide()

    hide: =>
        @checked = {}
        @visible = false
        @$el.hide()
        $('#installed input[type=checkbox], #pkgs input[type=checkbox]')
            .prop('checked', false)

    on_install: (event) =>
        @action 'install'

    on_uninstall: (event) =>
        @action 'remove'

    on_update: (event) =>
        @action 'update'

    on_uncheck_all: (event) =>
        @hide()

    action: (action) ->
        @pkg = _.keys(@checked)

        env = @envs.get_active()
        promise = env.attributes[action]({
            packages: @pkg,
            dryRun: true
        })

        promise.then @on_plan(action)
        @loading = new LoadingModal.View({ title: "Generating plan..." })
        @loading.show()
        @hide()

    on_plan: (action) =>
        (data) =>
            @loading.hide()
            if data.success? and data.success
                if data.message?
                    new Dialog.View({ message: data.message, type: "Message" }).show()
                else
                    new PlanModal.View({
                        pkg: @pkg,
                        envs: @envs,
                        pkgs: @pkgs,
                        actions: data.actions,
                        action: action
                    }).show()
            else
                new Dialog.View({ message: data.error, type: "Error" }).show()

_instance = null
instance = (el=null, envs=null, pkgs=null) ->
    if not _instance?
        _instance = new PackageActionsBar({ el: el, envs: envs, pkgs: pkgs })
    _instance

module.exports.instance = instance
