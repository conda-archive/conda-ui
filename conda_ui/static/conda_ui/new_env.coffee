define [
    "jquery"
    "conda_ui/api"
    "conda_ui/env_modal"
], ($, api, EnvModal) ->

    class NewEnvView extends EnvModal.View

        title_text: () -> "Create environment"

        submit_text: () -> "Create"

        doit: (new_name) ->
            api("envs/new/#{new_name}", {}, @on_env_new)

        on_env_new: (data) =>
            # TODO

    return {View: NewEnvView}
