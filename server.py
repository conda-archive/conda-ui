#!/usr/bin/env python

from __future__ import print_function

import sys
import argparse
import werkzeug.serving

def start_server():
    from package_manager import app
    app.run()

def start_server_with_reloader():
    def helper():
        start_server()

    werkzeug.serving.run_with_reloader(helper)

def run():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--debug",
        action = "store_true",
        default = False,
    )

    args = parser.parse_args(sys.argv[1:])

    if args.debug:
        start_server_with_reloader()
    else:
        start_server()

if __name__ == "__main__":
    try:
        run()
    except KeyboardInterrupt:
        print("Shutting down wakari-app-package-manager ...")
