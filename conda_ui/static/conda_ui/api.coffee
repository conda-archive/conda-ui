
var $ = require('jquery')
var conda = require("condajs")
conda.API_ROOT = '/condajs'

    errored = false
    error_message = "Could not connect to Conda server. Please restart server and refresh this page."
    $(document).ajaxError () ->
      if not errored
        window.alert(error_message)
        errored = true
        $('#main-tabs').html("<h2>#{error_message}</h2>")

module.exports.conda = conda
