class Env extends Backbone.Model
    defaults: -> {}

class Envs extends Backbone.Collection
    model: Env
    url: () -> "/api/envs"
    parse: (response) -> response.envs

    get_by_name: (name) ->
        _.find(@models, (env) -> env.get('name') == name)

    get_default: () ->
        _.find(@models, (env) -> env.get('default'))

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
        @listenTo(@collection, 'reset', @render)
        @render()

    tagName: 'select'

    render: () ->
        envs = @collection.models
        options = for env in envs
            name = env.get('name')
            text = name + (if env.get('default') then ' *' else '')
            option = $('<option>').attr(value: name).text(text)
            if env.get('default')
                option.attr(selected: "selected")
            else
                option
        @$el.addClass("form-control").html(options)
        @$el.change(@on_change)

    on_change: (event) =>
        @collection.set_active($(event.target).val())

class EnvsToolbarView extends Backbone.View
    initialize: (options) ->
        super(options)
        @view = new EnvsView(collection: options.envs)
        @render()

    tagName: 'div'

    button: (text) ->
        $('<button class="btn btn-default"></button>').text(text)

    render: () ->
        $select = @view.$el
        $buttons = (@button(text) for text in ['Activate', 'Delete', 'Clone', 'New'])
        $form_group = $('<div class="form-group">').html($select)
        $btn_group = $('<div class="btn-group">').html($buttons)
        @$el.html([$form_group, "&nbsp;", $btn_group])

class SearchView extends Backbone.View
    initialize: (options) ->
        super(options)
        @envs = options.envs
        @render()

    events:
        'keyup input': 'on_keyup'

    tagName: 'div'

    render: () ->
        $input = $('<input type="text" class="form-control" placeholder="Search packages">')
        $form_group = $('<div class="form-group">').html($input)
        @$el.html($form_group)

    on_keyup: (event) =>
        @envs.set_filter($(event.target).val())

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

            if filter? and name.indexOf(filter) == -1
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

    new EnvsToolbarView({el: $('#envs'), envs: envs})
    new SearchView({el: $('#search'), envs: envs})
    new PackagesView({el: $('#pkgs'), envs: envs, pkgs: pkgs})
