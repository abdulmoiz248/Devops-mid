from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from celery import Celery
from app.config import Config
import logging
from logging.handlers import RotatingFileHandler

# Initialize extensions
db = SQLAlchemy()
migrate = Migrate()
celery = Celery(__name__, broker=Config.CELERY_BROKER_URL, backend=Config.CELERY_RESULT_BACKEND)

def create_app():
    app = Flask(__name__)

    # Load configuration from Config class
    app.config.from_object(Config)

    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    celery.conf.update(app.config)

    # Register blueprints
    from app.routes import register_blueprints
    register_blueprints(app)

    # Logging configuration
    if not app.debug:
        handler = RotatingFileHandler('app.log', maxBytes=10240, backupCount=10)
        handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
        app.logger.addHandler(handler)
        app.logger.setLevel(logging.INFO)

    return app
