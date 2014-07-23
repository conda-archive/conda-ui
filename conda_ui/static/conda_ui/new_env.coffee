define [
    "jquery"
    "conda_ui/api"
    "conda_ui/env_modal"
], ($, api, EnvModal) ->

    class NewEnvView extends EnvModal.View

        title_text: () -> "Create environment"

        submit_text: () -> "Create"

        doit: (new_name) ->
            progress = api.conda.Env.create({
                name: new_name
                packages: ['python']
                progress: true
            })
            progress.then @on_env_new(new_name)

            @add_progress(progress)
            @disable_buttons()

        on_env_new: (new_name) =>
            (data) =>
                @hide()
                env = data.env
                Promise.all([env.linked(), env.revisions()]).then =>
                    @envs.add env
                    @envs.set_active new_name
                    @envs.reset(@envs.models)

    return {View: NewEnvView}
