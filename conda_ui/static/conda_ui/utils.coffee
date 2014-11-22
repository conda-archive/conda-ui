spritf = require('sprintf')

human_readable = (n) ->
    if n < 1024
        return sprintf.sprintf('%d B', n)
    k = n/1024
    if k < 1024
        return sprintf.sprintf('%d KB', Math.round(k))
    m = k/1024
    if m < 1024
        return sprintf.sprintf('%.1f MB', m)
    g = m/1024
    return sprintf.sprintf('%.2f GB', g)

on_windows = ->
    /windows/.test(navigator.userAgent.toLowerCase())

is_windows_ignored = (name) ->
    name is 'python' or name is 'psutil' or name is 'pycosat'

module.exports.human_readable = human_readable
module.exports.on_windows = on_windows
module.exports.is_windows_ignored = is_windows_ignored
