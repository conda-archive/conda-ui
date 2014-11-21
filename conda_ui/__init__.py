import sys
import argparse
import webbrowser

from flask import Flask, Blueprint, url_for

import tornado.ioloop
import tornado.web
import tornado.wsgi
import sockjs.tornado

blueprint = Blueprint('views', __name__)
from . import views

def static(filename):
    return url_for('static', filename=filename)

def start_server(args):
    app = Flask(__name__)
    app.config['SECRET_KEY'] = 'secret'
    app.jinja_env.globals['static'] = static

    blueprint.url_prefix = args.url_prefix
    app.register_blueprint(blueprint)

    # app.run(port=args.port, debug=args.debug)

    wsgi_app = tornado.wsgi.WSGIContainer(app)
    condajs_ws = sockjs.tornado.SockJSRouter(views.CondaJsWebSocketRouter, '/condajs_ws')
    routes = condajs_ws.urls
    routes.append((r".*", tornado.web.FallbackHandler, dict(fallback=wsgi_app)))
    application = tornado.web.Application(routes, debug=args.debug)

    try:
        application.listen(args.port)
    except OSError as e:
        print("There was an error starting the server:")
        print(e)
        return

    ioloop = tornado.ioloop.IOLoop.instance()
    if not args.debug:
        callback = lambda: webbrowser.open_new_tab('http://localhost:%s' % args.port)
        ioloop.add_callback(callback)
    else:
        print("listening at http://localhost:%s" % args.port)
    ioloop.start()


def main():
    parser = argparse.ArgumentParser(description="Web user interface for Conda")
    parser.add_argument("-d", "--debug", action="store_true", default=False)
    parser.add_argument("-p", "--port", type=int, default=4888)
    parser.add_argument("--url-prefix", default=None)

    args = parser.parse_args()
    start_server(args)

if __name__ == '__main__':
    main()
