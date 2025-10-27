#!/usr/bin/env python
"""
Celery worker entry point.
This file is used by the celery worker to load the Celery app and discover tasks.
"""
from app import create_app, celery, db


flask_app = create_app()


celery.conf.update(flask_app.config)


class ContextTask(celery.Task):
    def call(self, args, **kwargs):
        with flask_app.app_context():
            return self.run(args, **kwargs)

celery.Task = ContextTask


from app.tasks import image_tasks  # noqa: F401

if __name__== 'main':
    celery.start()
