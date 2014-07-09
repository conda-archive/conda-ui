define [
    "jquery"
    "conda_ui/api"
    "conda_ui/env_modal"
], ($, api, EnvModal) ->

    class NewEnvView extends EnvModal.View

        title_text: () -> "Create environment"

        submit_text: () -> "Create"

        doit: (new_name) ->
            api.conda.Env.create({
                name: new_name
                packages: ['python']
            }).then @on_env_new(new_name)

        on_env_new: (new_name) =>
            (data) =>
                console.log data
                env = data.env
                Promise.all([env.linked(), env.revisions()]).then =>
                    @envs.add env
                    @envs.reset(@envs.models)

    return {View: NewEnvView}
