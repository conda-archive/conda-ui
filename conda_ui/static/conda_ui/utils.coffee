define [
    "sprintf"
], (sprintf) ->

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

    return {human_readable: human_readable}
