from flask import Blueprint
from .upload_routes import upload_routes
from .status_routes import status
from .webhooks_routes import webhook


def register_blueprints(app):
    """Register all blueprints."""
    app.register_blueprint(upload_routes)
    app.register_blueprint(status_routes)
    app.register_blueprint(webhook)
