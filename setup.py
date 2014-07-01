import sys

from setuptools import setup

setup(
    name='conda-ui',
    version='1.0.0',
    author='Continuum Analytics',
    author_email='wakari-dev@continuum.io',
    description='Package manager for Wakari',
    install_requires=['Flask', 'werkzeug', 'conda'],
)
