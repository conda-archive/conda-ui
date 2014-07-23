define [
    "jquery",
    "condajs"
], ($, conda) ->
    conda.API_ROOT = '/condajs'

    $(document).ajaxError () ->
        alert("Could not connect to Conda server. Please restart server and refresh this page.")

    return { conda: conda }
