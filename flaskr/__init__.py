import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()

def create_app():
    app = Flask(__name__, instance_relative_config=True)
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev')
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///flaskr.sqlite'
    db.init_app(app)
    Migrate(app, db)

    from . import models  # noqa: F401 — needed so Migrate can see all tables

    from .routes import bp
    app.register_blueprint(bp)

    return app