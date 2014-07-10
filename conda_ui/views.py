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

def parse(subcommand, flags, positional):
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

    return cmdList


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

    cmdList = parse(subcommand, flags, positional)

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

import sockjs.tornado
import tornado.iostream
import subprocess
class CondaJsWebSocketRouter(sockjs.tornado.SockJSConnection):
    def on_message(self, message):
        message = json.loads(message)
        subcommand = message['subcommand']
        flags = message['flags']
        positional = message['positional']

        # http://stackoverflow.com/a/14281904/262727
        # Use subprocess here to take advantage of Tornado's async process
        # routines.
        cmdList = parse(subcommand, flags, positional)
        self.subprocess = subprocess.Popen(cmdList, stdout=subprocess.PIPE)
        self.stream = tornado.iostream.PipeIOStream(self.subprocess.stdout.fileno())
        self.stream.read_until(b'\n', self.on_newline)

    def on_newline(self, data):
        # We don't know if there's going to be more progressbars or if
        # everything is done. Thus, we read to a newline, try to parse it as
        # JSON - the progressbar formatter will put all its JSON on one
        # line, while the --json formatter will not. If it parses, continue
        # looking for progressbars, else read everything else and send the
        # result.
        data = data.decode('utf-8')
        try:
            data = json.loads(data)
            self.send(json.dumps({ 'progress': data }))
            self.stream.read_bytes(
                1,
                lambda x: self.stream.read_until(b'\n', self.on_newline)
            ) # get rid of the null byte
        except ValueError:
            self.buf = data
            self.stream.read_until_close(self.on_close)

    def on_close(self, data):
        self.send(json.dumps({ 'finished': json.loads(self.buf + data.decode('utf-8')) }))
