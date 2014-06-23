#!/usr/bin/env python

from __future__ import print_function

if __name__ == "__main__":
    import package_manager

    try:
        package_manager.run()
    except KeyboardInterrupt:
        print("Shutting down wakari-app-package-manager ...")
