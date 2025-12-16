"""Initialize database tables"""
import sys
import os

try:
    from app import create_app, db

    app = create_app()

    with app.app_context():
        print("Creating database tables...")
        db.create_all()
        print("Database tables created successfully!")
except Exception as e:
    print(f"Warning: Database initialization failed: {e}")
    print("Application will start without database initialization.")
    print("This is normal if running without a database or if the database is not yet available.")
    # Exit with 0 to not block container startup
    sys.exit(0)