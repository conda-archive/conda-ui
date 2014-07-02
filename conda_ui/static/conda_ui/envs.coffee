define [
    "underscore"
    "jquery"
    "backbone"
    "conda_ui/api"
    "conda_ui/delete_env"
    "conda_ui/clone_env"
    "conda_ui/new_env"
], (_, $, Backbone, api, DeleteEnv, CloneEnv, NewEnv) ->

    class Env extends Backbone.Model
        defaults: -> {}

    class Envs extends Backbone.Collection
        model: Env
        url: () -> "/api/envs"
        parse: (response) -> response.envs

        get_by_name: (name) ->
            _.find(@models, (env) -> env.get('name') == name)

        get_default: () ->
            _.find(@models, (env) -> env.get('is_default'))

        get_active: () ->
            @_active || @get_default()

        set_active: (name) ->
            @_active = @get_by_name(name)
            @trigger("activate", @_active)

    class EnvsView extends Backbone.View
        initialize: (options) ->
            super(options)
            @envs = options.envs
            @listenTo(@envs, 'activate', @on_activate)
            @listenTo(@envs, 'reset', () => @render())
            @render()

        tagName: 'div'

        button: (text) ->
            $('<button type="button" class="btn btn-default"></button>').text(text)

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

            @$activate_btn = @button('Activate').click(@on_activate_click)
            @$delete_btn = @button('Delete').click(@on_delete_click)
            @$clone_btn = @button('Clone').click(@on_clone_click)
            @$new_btn = @button('New').click(@on_new_click)

            @update_buttons()

            $buttons = [@$activate_btn, @$delete_btn, @$clone_btn, @$new_btn]
            $btn_group = $('<div class="btn-group">').html($buttons)
            @$el.html([$form_group, "&nbsp;", $btn_group])

        on_change: (event) =>
            @envs.set_active($(event.target).val())

        on_activate: (active) =>
            @update_buttons(active)

        update_buttons: (active) ->
            active || (active = @envs.get_active())

            if active?
                if active.get('is_default')
                    @$activate_btn.attr(disabled: "disabled")
                else
                    @$activate_btn.removeAttr("disabled")

                if active.get('is_root')
                    @$delete_btn.attr(disabled: "disabled")
                else
                    @$delete_btn.removeAttr("disabled")

        on_activate_click: (event) =>
            env = @envs.get_active()
            api("env/#{env.get('name')}/activate", {}, @on_env_activate)

        on_delete_click: (event) =>
            new DeleteEnv.View(envs: @envs).show()

        on_clone_click: (event) =>
            new CloneEnv.View(envs: @envs).show()

        on_new_click: (event) =>
            new NewEnv.View(envs: @envs).show()

        on_env_activate: (data) =>
            # TODO

    return {Model: Env, Collection: Envs, View: EnvsView}
