#!/usr/bin/env python

from __future__ import print_function

import sys
import argparse

def start_server(args):
    from package_manager import app
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

if __name__ == "__main__":
    try:
        run()
    except KeyboardInterrupt:
        print("Shutting down wakari-app-package-manager ...")
