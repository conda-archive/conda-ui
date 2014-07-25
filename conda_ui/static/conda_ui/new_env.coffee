define [
    "jquery"
    "conda_ui/api"
    "conda_ui/env_modal"
], ($, api, EnvModal) ->

    class NewEnvView extends EnvModal.View

        title_text: () -> "Create environment"

        submit_text: () -> "Create"

        render_body: () ->
            super()
            python = @pkgs.get_by_name('python')
            if not python or not @envs.get_active()
                # Collection hasn't loaded yet, let conda deal with it
                @$form

            installed = @envs.get_active().get('installed').python

            $label = $('<label>Python Version</label>')
            @$python = $('<select class="form-control" name="python"></select>')
            $help = $('<span class="help-block">Pick the Python version to install.</span>')
            $form_group = $('<div class="form-group">').append([$label, @$python, $help])
            @$form.append($form_group)

            for pkg in python.get('pkgs')
                $option = $('<option></option>').text("#{pkg.version}-#{pkg.build}")
                if pkg.version is installed.version and pkg.build is installed.build
                    $option.prop('selected', true)
                @$python.append($option)

            @$form

        doit: (new_name) ->
            python = 'python'
            if @$python?
                python += '=' + @$python.val().replace('-', '=')

            progress = api.conda.Env.create({
                name: new_name
                packages: [python]
                progress: true
                forcePscheck: true
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
