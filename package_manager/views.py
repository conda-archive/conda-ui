from flask import render_template, jsonify, redirect, abort, request, url_for

from . import app

from conda import config
from conda.api import get_index
from conda.envs import Env, get_envs
from conda.resolve import Resolve, MatchSpec
from conda.install import linked

@app.route('/')
def index():
    from conda.api import get_index
    from conda.resolve import Resolve, MatchSpec

    envs = [Env()] + get_envs()
    pkgs = []

    resolve = Resolve(get_index(use_cache=True))
    groups = []

    linked_pkgs = [ dist.rsplit('-', 2) for dist in linked(config.default_prefix) ]
    installed = { name: (version, build) for (name, version, build) in linked_pkgs }

    for name in sorted(resolve.groups):
        pkgs = resolve.get_pkgs(MatchSpec(name))
        installed_version = installed.get(name)
        if installed_version is not None:
            installed_version = installed_version[0]
        latest_version = pkgs[-1].version
        groups.append((name, installed_version, latest_version, pkgs))

    return render_template('index.html', envs=envs, groups=groups)
