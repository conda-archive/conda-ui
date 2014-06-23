from flask import render_template, jsonify, redirect, abort, request, url_for

from . import app

from conda import config
from conda.api import get_index
from conda.envs import Env, get_envs
from conda.resolve import Resolve, MatchSpec

@app.route('/')
def index():
    from conda.api import get_index
    from conda.resolve import Resolve, MatchSpec

    envs = [Env()] + get_envs()
    pkgs = []

    resolve = Resolve(get_index(use_cache=True))

    for group in sorted(resolve.groups):
        for pkg in resolve.get_pkgs(MatchSpec(group)):
            pkgs.append(pkg)

    return render_template('index.html', envs=envs, pkgs=pkgs)
