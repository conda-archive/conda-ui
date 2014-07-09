from __future__ import print_function, division, absolute_import

import re
import sys
import json
from io import StringIO
from os.path import isfile
from flask import render_template, jsonify, redirect, abort, request, url_for

from . import blueprint

import conda.cli as cli

@blueprint.route('/')
def index_view():
    return render_template('index.html')

_convert_re = re.compile('([A-Z])')
def convert(key):
    return "--" + _convert_re.sub(lambda match: '-' + match.group(0).lower(), key)

@blueprint.route('/condajs/<subcommand>', methods=['GET', 'POST'])
def api_condajs(subcommand):
    if request.method == 'GET':
        flags = request.args.copy()
    else:
        flags = json.loads(request.data.decode('utf-8'))

    positional = []
    if 'positional' in flags:
        positional = flags['positional']
        del flags['positional']

    cmdList = ['conda', subcommand, '--json']

    for key, value in flags.items():
        try:
            value = {
                'true': True,
                'false': False,
                'null': None
            }[value]
        except KeyError:
            pass

        if value is not False and value is not None:
            cmdList.append(convert(key))
            if isinstance(value, (list, tuple)):
                cmdList.extend(value)
            elif value is not True:
                cmdList.append(value)

    if isinstance(positional, str):
        cmdList.append(positional)
    else:
        cmdList.extend(positional)

    stdout = StringIO()
    old = sys.stdout
    sys.stdout = stdout
    sys.argv = cmdList
    try:
        cli.main()
    except SystemExit:
        pass
    sys.stdout = old
    stdout.seek(0)
    return stdout.read()
