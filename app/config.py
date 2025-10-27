import os


class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'a-very-secret-key'
    SQLALCHEMY_DATABASE_URI = 'postgresql://postgres:1234@localhost:5432/image_processing'
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # Celery settings
    CELERY_BROKER_URL = os.environ.get('CELERY_BROKER_URL') or 'amqp://localhost//'
    CELERY_RESULT_BACKEND = os.environ.get('CELERY_RESULT_BACKEND') or 'rpc://'

    # File upload settings
    UPLOAD_FOLDER = os.environ.get('UPLOAD_FOLDER') or '/tmp/uploads'
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16 MB

    # Image output and CSV output directories
    IMAGE_OUTPUT_DIR = os.environ.get('IMAGE_OUTPUT_DIR') or '/tmp/output_images'
    OUTPUT_CSV_DIR = os.environ.get('OUTPUT_CSV_DIR') or '/tmp/output_csvs'
