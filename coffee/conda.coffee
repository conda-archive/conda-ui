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

    get_filter: () ->
        @_filter

    set_active: (name) ->
        @_active = @get_by_name(name)
        @trigger("activate", @_active)

    set_filter: (filter) ->
        @_filter = filter
        @trigger("filter", @_filter)

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
        $.ajax({url: "/api/env/#{env.name}/activate", type: 'POST'})

    on_delete_click: (event) =>
        env = @envs.get_active()
        $.ajax({url: "/api/env/#{env.name}/delete", type: 'POST'})

    on_clone_click: (event) =>
        new CloneEnvView({env: @envs.get_active()}).show()

    on_new_click: (event) =>
        new NewEnvView().show()

class ModalView extends Backbone.View
    initialize: (options) ->
        super(options)
        @render()

    show: () ->
        @$el.modal('show')

    hide: () ->
        @$el.modal('hide')

    toggle: () ->
        @$el.modal('toggle')

    tagName: 'div'

    render: () ->
        $close = $('<button type="button" class="close">&times;</button>').click(@on_cancel)
        $title = $('<h4 class="modal-title">').append(@render_title())
        $header = $('<div class="modal-header">').append([$close, $title])
        $body = $('<div class="modal-body">').append(@render_body())
        $submit = $('<button type="button" class="btn btn-primary"></button>').text(@submit_text()).click(@on_submit)
        $cancel = $('<button type="button" class="btn btn-default"></button>').text(@cancel_text()).click(@on_cancel)
        $footer = $('<div class="modal-footer">').append([$submit, $cancel])
        $content = $('<div class="modal-content">').append([$header, $body, $footer])
        $dialog = $('<div class="modal-dialog">').append($content)
        @$el.addClass("modal fade").append($dialog).modal({show: false})
        @$el.on('shown.bs.modal', @on_shown)
        @$el.on('hidden.bs.modal', @on_hidden)
        $('body').append(@$el)

    render_title: () -> ""

    render_body: () -> ""

    submit_text: () -> "Submit"

    cancel_text: () -> "Cancel"

    on_submit: (event) =>

    on_cancel: (event) =>
        @hide()

    on_shown: (event) =>

    on_hidden: (event) =>
        @remove()

class SettingsView extends ModalView

    render_title: () -> "Settings"

    render_body: () -> "TODO: Settings"

class CloneEnvView extends ModalView

    render_title: () -> "CloneEnv"

    render_body: () -> "TODO: CloneEnv"

    submit_text: () -> "Clone"

    on_submit: (event) ->
        $.ajax({url: "/api/env/#{@env.name}/clone/#{new_name}", type: 'POST'})

class NewEnvView extends ModalView

    render_title: () -> "NewEnv"

    render_body: () -> "TODO: NewEnv"

    submit_text: () -> "Create"

    on_submit: (event) ->
        $.ajax({url: "/api/envs/new/#{new_name}", type: 'POST'})

class SearchView extends Backbone.View
    initialize: (options) ->
        super(options)
        @envs = options.envs
        @listenTo(@envs, 'filter', @on_filter)
        @render()

    events:
        'keyup input': 'on_keyup'

    tagName: 'div'

    render: () ->
        @$input = $('<input type="text" class="form-control" placeholder="Search packages">')
        $form_group = $('<div class="form-group">').html(@$input)
        @$close = $('<button type="button" class="btn btn-default" disabled="disabled"><span class="close">&times;</span></button>')
        @$close.click(@on_click)
        @$el.html([$form_group, "&nbsp;", @$close])

    on_keyup: (event) =>
        @envs.set_filter(@$input.val())

    on_click: (event) =>
        @$input.val("")
        @envs.set_filter("")

    on_filter: (filter) =>
        if filter? and filter.length
            @$close.removeAttr("disabled")
        else
            @$close.attr(disabled: "disabled")

class Package extends Backbone.Model
    defaults: -> {}

class Packages extends Backbone.Collection
    model: Package
    url: () -> "/api/pkgs"
    parse: (response) -> response.groups

class PackagesView extends Backbone.View

    initialize: (options) ->
        super(options)
        @envs = options.envs
        @pkgs = options.pkgs
        @listenTo(@envs, 'all', () => @render())
        @listenTo(@pkgs, 'reset', () => @render())
        @render()

    render: () ->
        env = @envs.get_active()
        if not env? then return

        headers = ['Status', 'Package Name', 'Installed Version', 'Latest Version']
        $headers = $('<tr>').html($('<th>').text(text) for text in headers)

        installed = env.get('installed')
        filter = @envs.get_filter()

        $rows = for pkg in @pkgs.models
            name = pkg.get('name')
            pkgs = pkg.get('pkgs')

            if filter? and filter.length != 0 and name.indexOf(filter) == -1
                continue

            latest_version = pkgs[pkgs.length-1].version
            installed_version = installed[name]?.version

            $status = $('<td><input type="checkbox"></td>')
            $name = $('<td>').text(name)
            $installed_version = $('<td>&mdash;</td>')
            $latest_version = $('<td>').text(latest_version)

            if installed_version?
                $status.find('input').attr(checked: 'checked')
                $installed_version.text(installed_version)

            $('<tr>').html([$status, $name, $installed_version, $latest_version])

        $table = $('<table class="table table-bordered table-striped">')
        $table.append($('<thead>').html($headers))
        $table.append($('<tbody>').html($rows))
        @$el.html($table)

$(document).ready () ->
    envs = new Envs()
    envs.fetch(reset: true)

    pkgs = new Packages()
    pkgs.fetch(reset: true)

    new EnvsView({el: $('#envs'), envs: envs})
    new SearchView({el: $('#search'), envs: envs})
    new PackagesView({el: $('#pkgs'), envs: envs, pkgs: pkgs})

    $('#settings').click (event) =>
        new SettingsView().show()
