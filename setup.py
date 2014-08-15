from __future__ import print_function

import sys
import subprocess

from os.path import join
from setuptools import setup, find_packages

def build():
    retcode = subprocess.call(
        ["coffee", "--no-header", "-c", join("conda_ui", "static", "conda_ui")],
        shell=(sys.platform == 'win32'))

    if retcode != 0:
        raise RuntimeError("compilation failed")

build()

setup(
    name='conda-ui',
    version='0.1.1',
    author='Continuum Analytics',
    author_email='conda@continuum.io',
    description='Web user interface for Conda',
    install_requires=['Flask', 'conda'],
    include_package_data=True,
    zip_safe=False,
    packages=find_packages(),
    entry_points={
        'console_scripts': [
            'conda-ui = conda_ui:main',
        ],
    },
)
