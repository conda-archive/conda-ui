from __future__ import print_function, division, absolute_import

import re
import sys
import json
from io import StringIO
from os.path import isfile
from flask import render_template, jsonify, redirect, abort, request, url_for

from . import blueprint

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
        except (TypeError, KeyError):
            pass

        if value is not False and value is not None:
            cmdList.append(convert(key))
            if isinstance(value, (list, tuple)):
                cmdList.extend(map(str, value))
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

    p = subprocess.Popen(cmdList, stdout=subprocess.PIPE)
    return p.communicate()[0]

import sockjs.tornado
import subprocess
import threading

class CondaSubprocessWorker(threading.Thread):
    def __init__(self, cmdList, send, *args, **kwargs):
        super(CondaSubprocessWorker, self).__init__(*args, **kwargs)
        self.cmdList = cmdList
        self.send = send

    def run(self):
        p = subprocess.Popen(self.cmdList, stdout=subprocess.PIPE)
        f = p.stdout
        while True:
            line = f.readline()

            if line[0] in (0, '\0'):
                line = line[1:]
            data = line.decode('utf-8')
            try:
                data = json.loads(data)
                self.send({ 'progress': data })
            except ValueError:
                rest = data + f.read().decode('utf-8')
                self.send({ 'finished': json.loads(rest) })
                break

class CondaJsWebSocketRouter(sockjs.tornado.SockJSConnection):
    def on_message(self, message):
        message = json.loads(message)
        subcommand = message['subcommand']
        flags = message['flags']
        positional = message['positional']

        # Use a thread here - Tornado's nonblocking pipe is not portable
        cmdList = parse(subcommand, flags, positional)
        self.worker = CondaSubprocessWorker(cmdList, self.process)
        self.worker.start()

    def process(self, data):
        self.send(json.dumps(data))
