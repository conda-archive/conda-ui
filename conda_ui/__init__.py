import sys
import argparse

from flask import Flask, url_for

def static(filename):
    return url_for('static', filename=filename)

app = Flask(__name__)
app.jinja_env.globals['static'] = static

def start_server(args):
    if args.debug:
        app.debug = True
    app.run()

def run():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--debug",
        action = "store_true",
        default = False,
    )

    args = parser.parse_args(sys.argv[1:])
    start_server(args)

from . import views
