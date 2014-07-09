define [
    "jquery"
    "conda_ui/api"
    "conda_ui/modal"
], ($, api, Modal) ->

    class DeleteEnvView extends Modal.View

        initialize: (options) ->
            @envs = options.envs
            super(options)

        title_text: () -> "Delete environment"

        render_body: () ->
            $name = $('<b>').text(@envs.get_active().get('name'))
            $('<span>').append(["Do you really want to delete ", $name, " environment?"])

        submit_text: () -> "Yes, remove this environment"
        cancel_text: () -> "No, I changed my mind"

        submit_type: () -> "danger"

        on_submit: (event) =>
            env = @envs.get_active()
            # Env.attributes is the conda-js Env object
            env.attributes.removeEnv().then @on_env_delete
            @hide()

        on_env_delete: (data) =>
            @envs.remove @envs.get_active()
            @envs.reset @envs.models
            @envs.set_active 'root'
            # TODO

    return {View: DeleteEnvView}
