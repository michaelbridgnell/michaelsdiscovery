import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

db = SQLAlchemy()
limiter = Limiter(key_func=get_remote_address, default_limits=[])

def create_app():
    app = Flask(__name__, instance_relative_config=True)
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev')
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///flaskr.sqlite'
    db.init_app(app)
    limiter.init_app(app)
    Migrate(app, db)

    from . import models  # noqa: F401 — needed so Migrate can see all tables

    from .routes import bp
    app.register_blueprint(bp)

    @app.after_request
    def security_headers(response):
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'DENY'
        response.headers['X-XSS-Protection'] = '1; mode=block'
        response.headers['Referrer-Policy'] = 'no-referrer'
        return response

    return app
