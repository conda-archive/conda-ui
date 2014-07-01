#!/usr/bin/env python

from __future__ import print_function

if __name__ == "__main__":
    import conda_ui

    try:
        conda_ui.run()
    except KeyboardInterrupt:
        print("Shutting down conda-ui ...")
