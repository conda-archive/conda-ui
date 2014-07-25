define [
    "ractive"
    "bootstrap_tagsinput"
    "promise"
    "conda_ui/api"
    "conda_ui/modal"
], (Ractive, $, Promise, api, Modal) ->
    class SettingsView extends Modal.View
        initialize: (options) ->
            @ractive = new Ractive({
                template: '#template-settings-dialog'
            })

            super()
            config = new api.conda.Config()
            defaults = {
                allow_softlinks: true,
                binstar_personal: true,
                changeps1: true,
                ssl_verify: true,
                use_pip: true
            }
            Promise.all([api.conda.info(), config.getAll()]).then (values) =>
                info = values[0]
                config = values[1]

                data = defaults
                data.info = info
                for own key, value of config
                    data[key] = value
                @ractive.reset data

                @$el.find('input[data-role=tagsinput]:not(#setting-envs-dirs)').tagsinput({
                    confirmKeys: [13, 32],  # Enter, space
                })
                @$el.find('#setting-envs-dirs').tagsinput({
                    confirmKeys: [13],  # Only Enter
                })

                @original = @get_values()

                @show()

            @ractive.on('clean', () => @on_clean())

        title_text: () -> "Settings"
        submit_text: () -> "Save"

        render_body: () ->
            el = $('<div></div>')
            @ractive.render(el)
            return el

        render: () ->
            super()
            @$el.addClass("scrollable-modal")

        on_submit: (event) =>
            @hide()
            values = @get_values()
            config = new api.conda.Config()
            for own key, value of values.boolean
                if value isnt @original.boolean[key]
                    config.set(key, value)

            for own key, changed of values.list
                original = @original.list[key]
                if typeof original is "undefined"
                    original = []

                added = []
                removed = []

                for val in original
                    if changed.indexOf(val) is -1
                        removed.push(val)
                for val in changed
                    if original.indexOf(val) is -1
                        added.push(val)

                for val in added
                    config.add(key, val)
                for val in removed
                    config.remove(key, val)

        get_values: ->
            boolean = {}
            list = {}
            @$('input[type=checkbox]').map (index, el) ->
                $el = $(el)
                boolean[$el.data('key')] = $el.prop('checked')
            @$('input[data-role=tagsinput]').map (index, el) ->
                $el = $(el)
                list[$el.data('key')] = Array.prototype.slice.call($el.tagsinput('items'))

            return { boolean: boolean, list: list }

        on_clean: (event) ->
            options = {}
            @$('#collapseClean input[type=checkbox]').each (i, el) ->
                $el = $(el)
                if $el.prop('checked')
                    options[$el.data('flag')] = true

            @$('#collapseClean .panel-body').text('Cleaning...')

            api.conda.clean(options).then =>
                @$('#collapseClean .panel-body').text('Cleaned!')

    return {View: SettingsView}
