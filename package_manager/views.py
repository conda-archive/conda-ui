from os.path import isfile
from flask import render_template, jsonify, redirect, abort, request, url_for

from . import app

from conda import config, plan
from conda.api import get_index
from conda.envs import Env, get_envs
from conda.resolve import Resolve, MatchSpec
from conda.install import linked, is_linked
from conda.history import History, is_diff
from conda.cli.common import specs_from_args

def get_resolve():
    return Resolve(get_index(use_cache=True))

def get_all_envs():
    return [Env()] + get_envs()

def get_env(name):
    return { env.name: env for env in get_all_envs() }[name]

def get_history(env):
    history = History(env.prefix)

    if not isfile(history.path):
        return None

    revisions = []

    for revision, (date, content) in enumerate(history.parse()):
        revisions.append(dict(
            revision = revision,
            date = " ".join(date.split(" ", 2)[:2]),
            diff = list(mk_diff(content)),
        ))

    return revisions

def mk_diff(content):
    if not is_diff(content):
        for dist in content:
            name, version, build = dist.rsplit('-', 2)
            yield dict(op="install", name=name, version=version, build=build)
    else:
        added = {}
        removed = {}
        for s in content:
            fn = s[1:]
            name, version, build = fn.rsplit('-', 2)
            if s.startswith('-'):
                removed[name.lower()] = (version, build)
            elif s.startswith('+'):
                added[name.lower()] = (version, build)
        changed = set(added) & set(removed)
        for name in sorted(changed):
            old, new = removed[name], added[name]
            op = "upgrade" if new > old else "downgrade"
            yield dict(op=op, name=name, old_version=old[0], new_version=new[0], old_build=old[1], new_build=new[1])
        for name in sorted(set(removed) - changed):
            yield dict(op="remove", name=name, version=removed[name][0], build=removed[name][1])
        for name in sorted(set(added) - changed):
            yield dict(op="install", name=name, version=added[name][0], build=added[name][1])

@app.route('/')
def index_view():
    return render_template('index.html')

@app.route('/api/envs', methods=['GET'])
def api_envs():
    envs = []

    for env in get_all_envs():
        history = get_history(env)
        installed = {}

        for dist in linked(env.prefix):
            name, version, build = dist.rsplit('-', 2)
            meta = is_linked(env.prefix, dist)
            # files = meta.get("files", [])
            installed[name] = dict(dist=dist, version=version, build=build) # , files=files)

        env = env.to_dict()
        env["history"] = history
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

@app.route('/api/env/<env_name>/plan', methods=['POST'])
def api_env_plan(env_name):
    data = request.get_json()

    env = get_env(env_name)
    resolve = get_resolve()

    try:
        specs = specs_from_args(data["specs"])
        actions = plan.install_actions(env.prefix, resolve.index, specs)
    except SystemExit as exc:
        return jsonify(ok=False, error=exc.message)

    def fix_actions(action_type):
        selected = actions.get(action_type)

        if selected is not None:
            selected = [ [dist] + dist.rsplit('-', 2) for dist in selected ]
            fixed = [ dict(dist=dist, name=name, version=version, build=build) for (dist, name, version, build) in selected ]
            actions[action_type] = fixed

    fix_actions('FETCH')
    fix_actions('EXTRACT')
    fix_actions('UNLINK')
    fix_actions('LINK')

    return jsonify(ok=True, actions=actions)

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
def api_envs_new(new_name):
    return jsonify(ok=True)
