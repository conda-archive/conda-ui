define [
    "jquery"
    "conda_ui/api"
    "conda_ui/env_modal"
], ($, api, EnvModal) ->

    class CloneEnvView extends EnvModal.View

        title_text: () -> "Clone environment"

        submit_text: () -> "Clone"

        doit: (new_name) ->
            api("env/#{@envs.get_active()}/clone/#{new_name}", {}, @on_env_clone)

        on_env_clone: (data) =>
            # TODO

    return {View: CloneEnvView}
