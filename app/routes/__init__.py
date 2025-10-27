from flask import Blueprint, current_app
from .upload_routes import upload_routes
from .status_routes import status
from .webhooks_routes import webhook
from .products_routes import products_routes


def register_blueprints(app):
    """Register all blueprints and add a simple route to serve the frontend index.html."""
    # Register API blueprints
    app.register_blueprint(upload_routes)
    app.register_blueprint(status)
    app.register_blueprint(webhook)
    app.register_blueprint(products_routes)

    # Serve the frontend index from the package static folder
    @app.route('/')
    def index():
        return current_app.send_static_file('index.html')
