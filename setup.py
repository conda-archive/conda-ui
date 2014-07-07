from __future__ import print_function

import sys
import subprocess

from setuptools import setup

def build():
    retcode = subprocess.call(["sh", "-ex", "compile"])

    if retcode != 0:
        raise RuntimeError("compilation failed")

build()

setup(
    name='conda-ui',
    version='1.0.0',
    author='Continuum Analytics',
    author_email='conda@continuum.io',
    description='Web user interface for Conda',
    install_requires=['Flask', 'conda'],
    include_package_data=True,
    zip_safe=False,
    packages=[
        'conda_ui',
    ],
    entry_points={
        'console_scripts': [
            'conda-ui = conda_ui:main',
        ],
    },
)
