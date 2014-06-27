human_readable = (n) ->
    if n < 1024
        return sprintf('%d B', n)
    k = n/1024
    if k < 1024
        return sprintf('%d KB', Math.round(k))
    m = k/1024
    if m < 1024
        return sprintf('%.1f MB', m)
    g = m/1024
    return sprintf('%.2f GB', g)

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

    set_active: (name) ->
        @_active = @get_by_name(name)
        @trigger("activate", @_active)

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
        $.ajax({url: "/api/env/#{env.get('name')}/activate", type: 'POST'})

    on_delete_click: (event) =>
        new DeleteEnvView(envs: @envs).show()

    on_clone_click: (event) =>
        new CloneEnvView(envs: @envs).show()

    on_new_click: (event) =>
        new NewEnvView(envs: @envs).show()

class ModalView extends Backbone.View
    initialize: (options) ->
        super(options)
        @render()

    show: () -> @$el.modal('show')
    hide: () -> @$el.modal('hide')

    toggle: () -> @$el.modal('toggle')

    tagName: 'div'

    render: () ->
        $header = $('<div class="modal-header">').append(@render_header())
        $body = $('<div class="modal-body">').append(@render_body())
        $footer = $('<div class="modal-footer">').append(@render_footer())
        $content = $('<div class="modal-content">').append([$header, $body, $footer])
        size_cls = switch @modal_size()
            when "large" then "modal-lg"
            when "small" then "modal-sm"
            else ""
        $dialog = $('<div class="modal-dialog">').append($content).addClass(size_cls)
        @$el.addClass("modal fade").append($dialog).modal({show: false})
        @$el.on('shown.bs.modal', @on_shown)
        @$el.on('hidden.bs.modal', @on_hidden)
        $('body').append(@$el)

    modal_size: () -> "default"

    title_text: () -> ""

    render_header: () ->
        $close = $('<button type="button" class="close">&times;</button>').click(@on_cancel)
        $title = $('<h4 class="modal-title">').append(@title_text())
        $close.add($title)
    render_body: () -> ""
    render_footer: () ->
        if @submit_text()?
            $submit = $('<button type="submit" class="btn"></button>')
                .addClass("btn-" + @submit_type()).text(@submit_text()).click(@on_submit)
        else
            $submit = $("")

        if @cancel_text()?
            $cancel = $('<button type="button" class="btn"></button>')
                .addClass("btn-" + @cancel_type()).text(@cancel_text()).click(@on_cancel)
        else
            $cancel = $("")

        $submit.add($cancel)

    submit_text: () -> "Submit"
    cancel_text: () -> "Cancel"

    submit_type: () -> "primary"
    cancel_type: () -> "default"

    on_submit: (event) =>
    on_cancel: (event) => @hide()

    on_shown: (event) =>
    on_hidden: (event) => @remove()

class SettingsView extends ModalView

    title_text: () -> "Settings"

    render_body: () -> "TODO: Settings"

class DeleteEnvView extends ModalView

    initialize: (options) ->
        @envs = options.envs
        super(options)

    title_text: () -> "Delete environment"

    render_body: () ->
        $name = $('<b>').text(@envs.get_active().get('name'))
        $('<span>').append(["Do you really want to delete ", $name, " environment?"])

    submit_text: () -> "Yes, remove this environment"
    cancel_text: () -> "No, I changed my mind"

    submit_type: () -> "danger"

    on_submit: (event) =>
        env = @envs.get_active()
        $.ajax({url: "/api/env/#{env.get('name')}/delete", type: 'POST'})
        @hide()

class EnvModalView extends ModalView

    initialize: (options) ->
        @envs = options.envs
        super(options)

    render_body: () ->
        $label = $('<label>Environment Name</label>')
        @$input = $('<input type="text" class="form-control" name="name" placeholder="Enter name">')
        $help = $('<span class="help-block">Letters, digits and symbols are allowed, but don\'t use slash character.</span>')
        $form_group = $('<div class="form-group">').append([$label, @$input, $help])
        @$form = $('<form role="form">').append($form_group)
        @$form.validate({
            submitHandler: @on_form_submit
            rules: {
                name: {
                    maxlength: 255
                    required: true
                    regex: /^[^\/]+$/
                    fn: (el) => (name) => not @envs.get_by_name(name)?
                }
            }
            messages: {
                name: {
                    regex: "Environment name must not contain slash (/) character."
                    fn: "Environment with this name already exists."
                }
            }
        })
        @$form

    on_submit: (event) =>
        @$form.submit()

    on_form_submit: (event) =>
        @doit(@$input.val())
        @hide()

class CloneEnvView extends EnvModalView

    title_text: () -> "Clone environment"

    submit_text: () -> "Clone"

    doit: (new_name) ->
        $.ajax({url: "/api/env/#{@envs.get_active()}/clone/#{new_name}", type: 'POST'})

class NewEnvView extends EnvModalView

    title_text: () -> "Create environment"

    submit_text: () -> "Create"

    doit: (new_name) ->
        $.ajax({url: "/api/envs/new/#{new_name}", type: 'POST'})

class SearchView extends Backbone.View
    initialize: (options) ->
        super(options)
        @pkgs = options.pkgs
        @listenTo(@pkgs, 'filter', @on_filter)
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
        @pkgs.set_filter(@$input.val())

    on_click: (event) =>
        @$input.val("")
        @pkgs.set_filter("")

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

    get_by_name: (name) ->
        _.find(@models, (pkg) -> pkg.get('name') == name)

    get_filter: () ->
        @_filter

    set_filter: (filter) ->
        @_filter = filter
        @trigger("filter", @_filter)

    do_filter: (name) ->
        @_filter? and @_filter.length != 0 and name.indexOf(@_filter) == -1

class PackagesView extends Backbone.View

    initialize: (options) ->
        super(options)
        @envs = options.envs
        @pkgs = options.pkgs
        @listenTo(@envs, 'all', () => @render())
        @listenTo(@pkgs, 'all', () => @render())
        @render()

    render: () ->
        env = @envs.get_active()
        if not env? then return

        headers = ['Status', 'Package Name', 'Installed Version', 'Latest Version']
        $headers = $('<tr>').html($('<th>').text(text) for text in headers)

        installed = env.get('installed')

        $rows = for pkg in @pkgs.models
            name = pkg.get('name')
            pkgs = pkg.get('pkgs')

            if @pkgs.do_filter(name)
                continue

            latest_version = pkgs[pkgs.length-1].version
            installed_version = installed[name]?.version

            $status = $('<td><input type="checkbox"></td>')
            $name = $('<td class="package-name">').text(name).data("package-name", name)
            $installed_version = $('<td>&mdash;</td>')
            $latest_version = $('<td>').text(latest_version)

            if installed_version?
                $status.find('input').attr(checked: 'checked')
                $installed_version.text(installed_version)

            $('<tr>').html([$status, $name, $installed_version, $latest_version])

        $table = $('<table class="table table-bordered table-striped">')
        $table.append($('<thead>').html($headers))
        $table.append($('<tbody>').html($rows))
        $table.on("click", ".package-name", @on_name_click)
        @$el.html($table)

    on_name_click: (event) =>
        name = $(event.target).data("package-name")
        pkg = @pkgs.get_by_name(name)
        new PackageModalView(pkg: pkg).show()

class PackageModalView extends ModalView

    initialize: (options) ->
        @pkg = options.pkg
        super(options)

    modal_size: () -> "large"

    title_text: () -> @pkg.get('name')

    submit_text: () -> "Install"

    render_body: () ->
        headers = ['Name', 'Version', 'Build', 'Size', 'Channel', 'Features']
        $headers = $('<tr>').html($('<th>').text(text) for text in headers)

        $rows = for pkg in @pkg.get('pkgs')
            $name = $('<td>').text(pkg.name)
            $version = $('<td>').text(pkg.version)
            $build = $('<td>').text(pkg.build)
            $size = $('<td>').text(human_readable(pkg.size))
            $channel = $('<td>').text(pkg.canonical_channel or pkg.channel).attr(title: pkg.channel)
            $features = $('<td>&mdash;</td>')

            if pkg.features.length > 0
                $features.text(pkg.features.join(", "))

            $('<tr>').html([$name, $version, $build, $size, $channel, $features])

        $table = $('<table class="table table-bordered table-striped">')
        $table.append($('<thead>').html($headers))
        $table.append($('<tbody>').html($rows))
        $table

    render: () ->
        super()
        @$el.addClass("packages-modal")

class InstalledView extends Backbone.View

    initialize: (options) ->
        super(options)
        @envs = options.envs
        @pkgs = options.pkgs
        @listenTo(@envs, 'all', () => @render())
        @listenTo(@pkgs, 'all', () => @render())
        @render()

    render: () ->
        env = @envs.get_active()
        if not env? then return

        headers = ['Name', 'Version', 'Build', 'Channel', 'Features']
        $headers = $('<tr>').html($('<th>').text(text) for text in headers)

        installed = env.get('installed')

        pkgs = for own name, info of installed
            pkg = @pkgs.get_by_name(name)
            if not pkg? then continue
            _.find(pkg.get('pkgs'), (pkg) -> pkg.dist == info.dist)

        pkgs = _.sortBy(pkgs, (pkg) -> pkg.name)

        $rows = for pkg in pkgs
            if @pkgs.do_filter(pkg.name)
                continue

            $name = $('<td>').text(pkg.name)
            $version = $('<td>').text(pkg.version)
            $build = $('<td>').text(pkg.build)
            $channel = $('<td>').text(pkg.canonical_channel or pkg.channel).attr(title: pkg.channel)
            $features = $('<td>&mdash;</td>')

            if pkg.features.length > 0
                $features.text(pkg.features.join(", "))

            $('<tr>').html([$name, $version, $build, $channel, $features])

        $table = $('<table class="table table-bordered table-striped">')
        $table.append($('<thead>').html($headers))
        $table.append($('<tbody>').html($rows))
        @$el.html($table)

class HistoryView extends Backbone.View

    initialize: (options) ->
        super(options)
        @envs = options.envs
        @pkgs = options.pkgs
        @listenTo(@envs, 'all', () => @render())
        @listenTo(@pkgs, 'filter', () => @render())
        @render()

    render: () ->
        env = @envs.get_active()
        if not env? then return

        history = env.get('history')

        if history?
            headers = ['Revision', 'Date', 'Name', 'Removed Version', 'Installed Version']
            $headers = $('<tr>').html($('<th>').text(text) for text in headers)

            mk_version = (version, build) -> $('<td>').text("#{version} (#{build})")
            mk_mdash = () -> $('<td>&mdash;</td>')

            $rows = for history_item in history
                for diff_item in history_item.diff
                    if @pkgs.do_filter(diff_item.name)
                        continue

                    $revision = $('<td>').text(history_item.revision)
                    $date = $('<td>').text(history_item.date)
                    $name = $('<td>').text(diff_item.name)

                    switch diff_item.op
                        when "add"
                            $new_version = mk_version(diff_item.version, diff_item.build)
                            $old_version = mk_mdash()
                            style = "success"
                        when "remove"
                            $new_version = mk_mdash()
                            $old_version = mk_version(diff_item.version, diff_item.build)
                            style = "danger"
                        when "modify"
                            $new_version = mk_version(diff_item.old_version, diff_item.old_build)
                            $old_version = mk_version(diff_item.new_version, diff_item.new_build)
                            style = "info"

                    $('<tr>').html([$revision, $date, $name, $old_version, $new_version]).addClass(style)

            $rows = _.flatten($rows, shallow=true)
            $table = $('<table class="table table-bordered">')
            $table.append($('<thead>').html($headers))
            $table.append($('<tbody>').html($rows))

            @$el.html($table)
        else
            @$el.html("History was not recorded for this environment.")

$.validator.setDefaults({
    highlight: (element) ->
        $(element).closest('.form-group').addClass('has-error')
    unhighlight: (element) ->
        $(element).closest('.form-group').removeClass('has-error')
    errorElement: 'span'
    errorClass: 'help-block validation'
    errorPlacement: (error, element) ->
        if element.parent('.input-group').length
            error.insertAfter(element.parent())
        else
            error.insertAfter(element)
})

$.validator.addMethod(
    "regex",
    ((value, element, regexp) ->
        re = new RegExp(regexp)
        this.optional(element) || re.test(value)
    ),
    "Please check your input.",
)

$.validator.addMethod(
    "fn",
    ((value, element, fn) ->
        this.optional(element) || fn(value)
    ),
    "Please check your input.",
)

$(document).ready () ->
    envs = new Envs()
    envs.fetch(reset: true)

    pkgs = new Packages()
    pkgs.fetch(reset: true)

    new EnvsView({el: $('#envs'), envs: envs})
    new SearchView({el: $('#search'), pkgs: pkgs})
    new PackagesView({el: $('#pkgs'), envs: envs, pkgs: pkgs})
    new InstalledView({el: $('#installed'), envs: envs, pkgs: pkgs})
    new HistoryView({el: $('#history'), envs: envs, pkgs: pkgs})

    $('#settings').click (event) =>
        new SettingsView().show()
