from flask import render_template, jsonify, redirect, abort, request, url_for

from . import app

@app.route('/')
def index():
    envs = []
    pkgs = []
    return render_template('index.html', envs=envs, pkgs=pkgs)
