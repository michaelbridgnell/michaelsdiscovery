import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_caching import Cache

db = SQLAlchemy()
limiter = Limiter(key_func=get_remote_address, default_limits=[])
cache = Cache()

def create_app():
    app = Flask(__name__, instance_relative_config=True)
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev')
    db_url = os.environ.get('DATABASE_URL', 'sqlite:///flaskr.sqlite')
    # Supabase/Render give postgres:// but SQLAlchemy needs postgresql://
    if db_url.startswith('postgres://'):
        db_url = db_url.replace('postgres://', 'postgresql://', 1)
    app.config['SQLALCHEMY_DATABASE_URI'] = db_url
    # In-memory cache — fast, zero dependencies, sufficient for a single-server free tier
    app.config['CACHE_TYPE'] = 'SimpleCache'
    app.config['CACHE_DEFAULT_TIMEOUT'] = 300   # 5 minutes

    db.init_app(app)
    limiter.init_app(app)
    cache.init_app(app)
    Migrate(app, db)

    from . import models  # noqa: F401 — needed so Migrate can see all tables

    from .routes import bp
    app.register_blueprint(bp)

    # Ensure all tables exist regardless of migration state
    with app.app_context():
        db.create_all()

    @app.after_request
    def security_headers(response):
        response.headers['X-Content-Type-Options'] = 'nosniff'
        response.headers['X-Frame-Options'] = 'DENY'
        response.headers['X-XSS-Protection'] = '1; mode=block'
        response.headers['Referrer-Policy'] = 'no-referrer'
        return response

    return app
