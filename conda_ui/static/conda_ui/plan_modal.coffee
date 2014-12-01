_ = require('underscore')
$ = require('jquery')
api = require('api')
utils = require('utils')
Modal = require('modal')
Dialog = require('dialog')
WindowsWarning = require('windows_warning_modal')

class PlanModalView extends Modal.View

    initialize: (options) ->
        @pkg = options.pkg
        @revision = options.revision
        @envs = options.envs
        @pkgs = options.pkgs
        @actions = options.actions
        @action = options.action
        @action_noun = switch @action
            when "update" then "Update"
            when "install" then "Installation"
            when "remove" then "Uninstallation"
            when "revert" then "Revert"
        @action_participle = switch @action
            when "update" then "updated"
            when "install" then "installed"
            when "remove" then "uninstalled"
            when "revert" then "reverted"
        super(options)

    title_text: () ->
        if _.isArray @pkg
            text = @pkg.join(', ')
        else if @action is 'revert'
            text = "revision #{@revision}"
        else
            text = @pkg.get('name')

        $("<span>#{@action_noun} plan for </span>").append($('<span>').text(text))

    submit_text: () -> "Proceed"

    render_body: () ->
        fetch = @actions['FETCH']
        unlink = @actions['UNLINK']
        link = @actions['LINK']

        $plan = $('<div>')

        if fetch?
            $description = $('<h5>The following packages will be downloaded:</h5>')

            headers = ['Name', 'Version', 'Build', 'Size']
            $headers = $('<tr>').html($('<th>').text(text) for text in headers)

            $rows = for pkg in fetch
                dist = pkg
                pkg = api.conda.Package.splitFn pkg
                pkg.dist = dist
                info = @pkgs.get_by_dist(pkg.name, pkg.dist)

                $name = $('<td>').text(pkg.name)
                $version = $('<td>').text(pkg.version)
                $build = $('<td>').text(pkg.build)
                $size = $('<td>').text(utils.human_readable(info.size))

                $columns = [$name, $version, $build, $size]
                $('<tr>').html($columns)

            $table = $('<table class="table table-bordered table-striped">')
            $table.append($('<thead>').html($headers))
            $table.append($('<tbody>').html($rows))

            $plan.append([$description, $table])

        if unlink?
            $description = $('<h5>The following packages will be UN-linked:</h5>')

            headers = ['Name', 'Version', 'Build']
            $headers = $('<tr>').html($('<th>').text(text) for text in headers)

            $rows = for pkg in unlink
                dist = pkg
                pkg = api.conda.Package.splitFn pkg
                pkg.dist = dist
                $name = $('<td class="col-plan-name">').text(pkg.name)
                $version = $('<td class="col-plan-version">').text(pkg.version)
                $build = $('<td class="col-plan-build">').text(pkg.build)

                $columns = [$name, $version, $build]
                $('<tr>').html($columns)

            $table = $('<table class="table table-bordered table-striped unlink">')
            $table.append($('<thead>').html($headers))
            $table.append($('<tbody>').html($rows))

            $plan.append([$description, $table])

        if link?
            $description = $('<h5>The following packages will be linked:</h5>')

            headers = ['Name', 'Version', 'Build']
            $headers = $('<tr>').html($('<th>').text(text) for text in headers)

            $rows = for pkg in link
                dist = pkg
                pkg = api.conda.Package.splitFn pkg
                pkg.dist = dist
                $name = $('<td class="col-plan-name">').text(pkg.name)
                $version = $('<td class="col-plan-version">').text(pkg.version)
                $build = $('<td class="col-plan-build">').text(pkg.build)

                $columns = [$name, $version, $build]
                $('<tr>').html($columns)

            $table = $('<table class="table table-bordered table-striped">')
            $table.append($('<thead>').html($headers))
            $table.append($('<tbody>').html($rows))

            $plan.append([$description, $table])

        @$progress = $('<div class="progress-bar" role="progressbar">')
        @$progress.css 'width', '0%'
        @$progress.hide()
        $plan.append $('<div class="progress progress-striped active">').append @$progress

        $plan

    on_submit: (event) =>
        WindowsWarning.warn().then =>
            @doit()

    doit: () =>
        @disable_buttons()
        env = @envs.get_active()

        if @action is 'revert'
            promise = env.attributes.install({
                revision: @revision
                progress: true
            })
        else
            promise = env.attributes[@action]({
                packages: if _.isArray @pkg then @pkg else [@pkg.get('name')]
                progress: true
            })
        promise.progress (info) =>
            @$progress.show()
            progress = 100 * (info.progress / info.maxval)
            percent = progress.toString() + '%'
            @$progress.css 'width', percent

            if typeof info.fetch isnt "undefined"
                label = 'Fetching... ' + info.fetch
            else
                label = 'Linking... '
            @$progress.html label
        promise.then(@on_install)

    on_install: (data) =>
        @hide()
        if data.success? and data.success
            action_participle = @action_participle
            @envs.fetch(reset: true)
            if _.isArray @pkg
                name = @pkg.join(', ') + (if @pkg.length is 1 then ' was' else ' were')
            else if @action is 'revert'
                name = @revision
            else
                name = @pkg.get('name') + ' was'
            new Dialog.View({type: "info", message: "#{name} successfully #{action_participle}"}).show()
        else
            @$progress.addClass 'progress-bar-error'
            new Dialog.View({type: "error", message: data.error}).show()

module.exports.View = PlanModalView
