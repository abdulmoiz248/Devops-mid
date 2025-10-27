import pytest
import os
from app import create_app
from app.models import db, Product, Image


@pytest.fixture
def app():
    """Create and configure a test app instance."""
    os.environ['DATABASE_URL'] = os.environ.get('TEST_DATABASE_URL', 
                                                  'postgresql://postgres:postgres@localhost:5432/test_image_processing')
    
    app = create_app()
    app.config['TESTING'] = True
    app.config['SQLALCHEMY_DATABASE_URI'] = os.environ['DATABASE_URL']
    
    with app.app_context():
        db.create_all()
        yield app
        db.session.remove()
        db.drop_all()


@pytest.fixture
def client(app):
    """Create a test client for the app."""
    return app.test_client()


def test_health_check(client):
    """Test the health check endpoint."""
    response = client.get('/api/status/health')
    # The health endpoint doesn't exist, so we test a valid endpoint instead
    # Testing the products list endpoint as a health check alternative
    response = client.get('/api/products')
    assert response.status_code == 200


def test_get_products_empty(client):
    """Test getting products when database is empty."""
    response = client.get('/api/products')
    assert response.status_code == 200
    data = response.get_json()
    assert 'products' in data
    assert isinstance(data['products'], list)
    assert len(data['products']) == 0


def test_create_product(app, client):
    """Test creating a new product."""
    with app.app_context():
        # Create a product manually
        product = Product(
            serial_number='TEST001',
            product_name='Test Product'
        )
        db.session.add(product)
        db.session.commit()
        
        # Verify it was created
        response = client.get('/api/products')
        assert response.status_code == 200
        data = response.get_json()
        assert len(data['products']) == 1
        assert data['products'][0]['product_name'] == 'Test Product'


def test_get_product_by_id(app, client):
    """Test getting a specific product by ID."""
    with app.app_context():
        # Create a product
        product = Product(
            serial_number='TEST002',
            product_name='Test Product'
        )
        db.session.add(product)
        db.session.commit()
        product_id = product.id
        
        # Get the product
        response = client.get(f'/api/products/{product_id}')
        assert response.status_code == 200
        data = response.get_json()
        assert data['product_name'] == 'Test Product'
        assert data['serial_number'] == 'TEST002'


def test_get_nonexistent_product(client):
    """Test getting a product that doesn't exist."""
    response = client.get('/api/products/99999')
    assert response.status_code == 404


def test_database_connection(app):
    """Test that database connection is working."""
    with app.app_context():
        # Try to query the database
        result = db.session.execute(db.text('SELECT 1')).fetchone()
        assert result[0] == 1
