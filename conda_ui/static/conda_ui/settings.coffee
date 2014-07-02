define [
    "conda_ui/modal"
], (Modal) ->

    class SettingsView extends Modal.View

        title_text: () -> "Settings"

        render_body: () -> "TODO: Settings"

    return {View: SettingsView}
