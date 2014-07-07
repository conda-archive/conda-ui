import sys
import argparse

from flask import Flask, Blueprint, url_for

blueprint = Blueprint('views', __name__)
from . import views

def static(filename):
    return url_for('static', filename=filename)

def start_server(args):
    app = Flask(__name__)
    app.jinja_env.globals['static'] = static

    blueprint.url_prefix = args.url_prefix
    app.register_blueprint(blueprint)

    app.run(port=args.port, debug=args.debug)

def main():
    parser = argparse.ArgumentParser(description="Web user interface for Conda")
    parser.add_argument("-d", "--debug", action="store_true", default=False)
    parser.add_argument("-p", "--port", type=int, default=4888)
    parser.add_argument("--url-prefix", default=None)

    args = parser.parse_args()
    start_server(args)

if __name__ == '__main__':
    main()
