define [
    "jquery"
    "conda_ui/api"
    "conda_ui/env_modal"
], ($, api, EnvModal) ->

    class DeleteEnvView extends EnvModal.View

        title_text: () -> "Delete environment"

        render_body: () ->
            $name = $('<b>').text(@envs.get_active().get('name'))
            $('<span>').append(["Do you really want to delete ", $name, " environment?"])

        submit_text: () -> "Yes, remove this environment"
        cancel_text: () -> "No, I changed my mind"

        submit_type: () -> "danger"

        doit: () =>
            env = @envs.get_active()
            # Env.attributes is the conda-js Env object
            progress = env.attributes.removeEnv({ progress: true, forcePscheck: true })
            progress.then @on_env_delete

            @add_progress(progress)
            @disable_buttons()

        on_env_delete: (data) =>
            @hide()
            @envs.remove @envs.get_active()
            @envs.reset @envs.models
            @envs.set_active 'root'
            # TODO

    return {View: DeleteEnvView}
