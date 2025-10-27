from flask import Blueprint, request, jsonify
from app.models import Product, Image, db
from sqlalchemy.exc import IntegrityError

products_routes = Blueprint('products', __name__, url_prefix='/api/products')


@products_routes.route('', methods=['GET'])
def list_products():
    """List all products with their image counts"""
    try:
        products = Product.query.all()
        result = []
        for product in products:
            result.append({
                'id': product.id,
                'serial_number': product.serial_number,
                'product_name': product.product_name,
                'image_count': len(product.images)
            })
        return jsonify({'products': result}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@products_routes.route('/<int:product_id>', methods=['GET'])
def get_product(product_id):
    """Get a single product with all its images"""
    try:
        product = Product.query.get_or_404(product_id)
        images = [{
            'id': img.id,
            'input_image_url': img.input_image_url,
            'output_image_url': img.output_image_url
        } for img in product.images]
        
        return jsonify({
            'id': product.id,
            'serial_number': product.serial_number,
            'product_name': product.product_name,
            'images': images
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 404


@products_routes.route('', methods=['POST'])
def create_product():
    """Create a new product"""
    try:
        data = request.get_json()
        
        if not data or 'serial_number' not in data or 'product_name' not in data:
            return jsonify({'error': 'serial_number and product_name are required'}), 400
        
        product = Product(
            serial_number=data['serial_number'],
            product_name=data['product_name']
        )
        
        db.session.add(product)
        db.session.commit()
        
        return jsonify({
            'id': product.id,
            'serial_number': product.serial_number,
            'product_name': product.product_name,
            'message': 'Product created successfully'
        }), 201
        
    except IntegrityError:
        db.session.rollback()
        return jsonify({'error': 'Product with this serial number already exists'}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@products_routes.route('/<int:product_id>', methods=['PUT'])
def update_product(product_id):
    """Update a product"""
    try:
        product = Product.query.get_or_404(product_id)
        data = request.get_json()
        
        if 'serial_number' in data:
            product.serial_number = data['serial_number']
        if 'product_name' in data:
            product.product_name = data['product_name']
        
        db.session.commit()
        
        return jsonify({
            'id': product.id,
            'serial_number': product.serial_number,
            'product_name': product.product_name,
            'message': 'Product updated successfully'
        }), 200
        
    except IntegrityError:
        db.session.rollback()
        return jsonify({'error': 'Product with this serial number already exists'}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@products_routes.route('/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    """Delete a product and all its images"""
    try:
        product = Product.query.get_or_404(product_id)
        db.session.delete(product)
        db.session.commit()
        
        return jsonify({'message': 'Product deleted successfully'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@products_routes.route('/images', methods=['GET'])
def list_all_images():
    """List all images across all products"""
    try:
        images = Image.query.all()
        result = []
        for img in images:
            result.append({
                'id': img.id,
                'product_id': img.product_id,
                'product_name': img.product.product_name,
                'serial_number': img.product.serial_number,
                'input_image_url': img.input_image_url,
                'output_image_url': img.output_image_url
            })
        return jsonify({'images': result}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500
