from flask import Flask, url_for

def static(filename):
    return url_for('static', filename=filename)

app = Flask(__name__)
app.jinja_env.globals['static'] = static

from . import views
