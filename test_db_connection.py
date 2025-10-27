from sqlalchemy import create_engine

DATABASE_URL = 'postgresql://postgres:1234@localhost:5432/image_processing'
engine = create_engine(DATABASE_URL)

try:
    connection = engine.connect()
    print("Connection successful!")
except Exception as e:
    print(f"Connection failed: {e}")
finally:
    connection.close()
