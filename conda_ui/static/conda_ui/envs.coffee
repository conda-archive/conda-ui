define [
    "underscore"
    "jquery"
    "backbone"
    "conda_ui/api"
    "conda_ui/delete_env"
    "conda_ui/clone_env"
    "conda_ui/new_env"
], (_, $, Backbone, api, DeleteEnv, CloneEnv, NewEnv) ->
    conda = api.conda

    class Env extends Backbone.Model
        defaults: -> {}

    class Envs extends Backbone.Collection
        model: Env

        filterfunc: (env) ->
            (['_build', '_test', '_pipbuild_'].indexOf(env.name) is -1 and
             env.name.slice(0, 20) isnt "_app_own_environment")

        sync: (method, model, options) ->
            if method is "read"
                @trigger 'request'
                conda.Env.getEnvs().then (envs) =>
                    promises = []
                    envs = envs.filter(@filterfunc, envs)
                    envs.forEach (env) ->
                        if env.is_default
                            promises.push env.linked()
                            promises.push env.revisions()

                    Promise.all(promises).then =>
                        options.success envs

                        if @_active
                            @set_active @_active.get('name')
            else
                console.log method

        get_by_name: (name) ->
            _.find(@models, (env) -> env.get('name') == name)

        get_default: () ->
            _.find(@models, (env) -> env.get('is_default'))

        get_active: () ->
            @_active || @get_default()

        set_active: (name) ->
            @_active = @get_by_name(name)
            if _.size(@_active.get('installed')) is 0 or @_active.get('history').length is 0
                @trigger("request", @_active)
                promises = [@_active.attributes.linked(), @_active.attributes.revisions()]
                Promise.all(promises).then =>
                    @trigger("activate", @_active)
            else
                @trigger("activate", @_active)

    class EnvsView extends Backbone.View
        initialize: (options) ->
            super(options)
            @envs = options.envs
            @pkgs = options.pkgs
            @listenTo(@envs, 'activate', @on_activate)
            @listenTo(@envs, 'reset', () => @render())
            @render()

        tagName: 'div'

        button: (text, icon=null) ->
            button = $('<button type="button" class="btn btn-default"></button>')
            if icon?
                button.append("<i class=\"fa fa-#{icon}\"></i>&nbsp;")
            button.append(text)

        render: () ->
            active = @envs.get_active()

            $options = for env in @envs.models
                name = env.get('name')
                text = name + (if env.get('is_default') then ' *' else '')
                option = $('<option>').attr(value: name).text(text)
                if env == active
                    option.attr(selected: "selected")
                else
                    option

            @$select = $('<select class="form-control">').html($options)
            $form_group = $('<div class="form-group">').html(@$select)

            @$select.change(@on_change)

            @$delete_btn = @button('Delete', 'trash-o').click(@on_delete_click).addClass('btn-danger')
            @$clone_btn = @button('Clone', 'copy').click(@on_clone_click)
            @$new_btn = @button('New', 'plus-square').click(@on_new_click).addClass('btn-success')
            @$refresh_btn = @button('Refresh', 'refresh')
                .click(@on_refresh_click)

            @update_buttons()

            $buttons = [@$delete_btn, @$clone_btn, @$new_btn]
            $btn_group = $('<div class="btn-group">').html($buttons)

            @$el.html([$form_group, "&nbsp;", $btn_group, "&nbsp;", @$refresh_btn])

        on_change: (event) =>
            @envs.set_active($(event.target).val())

        on_activate: (active) =>
            @update_buttons(active)
            @$select.find("option[value=#{active.get('name')}]").prop('selected', true)

        update_buttons: (active) ->
            active || (active = @envs.get_active())

            if active?
                if active.get('is_root')
                    @$delete_btn.attr(disabled: "disabled")
                else
                    @$delete_btn.removeAttr("disabled")

        on_delete_click: (event) =>
            new DeleteEnv.View(envs: @envs, pkgs: @pkgs).show()

        on_clone_click: (event) =>
            new CloneEnv.View(envs: @envs, pkgs: @pkgs).show()

        on_new_click: (event) =>
            new NewEnv.View(envs: @envs, pkgs: @pkgs).show()

        on_refresh_click: (event) =>
            @envs.fetch(reset: true)
            @pkgs.fetch(reset: true)

    return {Model: Env, Collection: Envs, View: EnvsView}
