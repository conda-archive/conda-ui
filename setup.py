from __future__ import print_function

import sys
import subprocess

from setuptools import setup, find_packages

def build():
    if sys.platform != 'win32':
        retcode = subprocess.call(["sh", "-ex", "compile"])
    else:
        retcode = subprocess.call(["coffee", "-c","conda_ui/static/conda_ui/*.coffee"])

    if retcode != 0:
        raise RuntimeError("compilation failed")

build()

setup(
    name='conda-ui',
    version='0.1.0',
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
