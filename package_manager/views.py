from flask import render_template, jsonify, redirect, abort, request, url_for

from . import app

from conda import config
from conda.api import get_index
from conda.envs import Env, get_envs
from conda.resolve import Resolve, MatchSpec
from conda.install import linked, is_linked

def get_resolve():
    return Resolve(get_index(use_cache=True))

def get_all_envs():
    return [Env()] + get_envs()

def get_env(name):
    return { env.name: env for env in get_all_envs() }[name]

@app.route('/')
def index_view():
    return render_template('index.html')

@app.route('/api/envs', methods=['GET'])
def api_envs():
    envs = []

    for env in get_all_envs():
        installed = {}

        for dist in linked(env.prefix):
            name, version, build = dist.rsplit('-', 2)
            meta = is_linked(env.prefix, dist)
            files = meta.get("files", [])
            installed[name] = dict(dist=dist, version=version, build=build, files=files)

        env = env.to_dict()
        env["installed"] = installed
        envs.append(env)

    return jsonify(envs=envs)

@app.route('/api/pkgs', methods=['GET'])
def api_pkgs():
    resolve = get_resolve()
    groups = []

    for name in sorted(resolve.groups):
        groups.append(dict(
            name = name,
            pkgs = [ pkg.to_dict() for pkg in resolve.get_pkgs(MatchSpec(name)) ],
        ))

    return jsonify(groups=groups)

@app.route('/api/env/<env_name>/activate', methods=['POST'])
def api_env_activate(env_name):
    return jsonify(ok=True)

@app.route('/api/env/<env_name>/delete', methods=['POST'])
def api_env_delete(env_name):
    return jsonify(ok=True)

@app.route('/api/env/<env_name>/clone/<new_name>', methods=['POST'])
def api_env_clone(env_name, new_name):
    return jsonify(ok=True)

@app.route('/api/envs/new/<new_name>', methods=['POST'])
def api_envs_new(new_new):
    return jsonify(ok=True)
