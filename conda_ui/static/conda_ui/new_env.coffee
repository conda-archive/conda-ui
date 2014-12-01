$ = require('jquery')
api = require('api')
EnvModal = require('env_modal')

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

        versions = []
        for pkg in python.get('pkgs')
            version = api.conda.Package.parseVersion(pkg.version)
            major_version = version.parts.slice(0, 2).join('.')
            if versions.indexOf(major_version) is -1
                versions.push(major_version)

        installed_major = api.conda.Package.parseVersion(installed.version)
            .parts.slice(0, 2).join('.')
        for version in versions
            $option = $('<option></option>').text(version)
            if version is installed_major
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

module.exports.View = NewEnvView
