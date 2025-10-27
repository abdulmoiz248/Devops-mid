from . import db

class Product(db.Model):
    __tablename__ = 'products'
    id = db.Column(db.Integer, primary_key=True)
    serial_number = db.Column(db.String(255), nullable=False, unique=True)
    product_name = db.Column(db.String(255), nullable=False)
    images = db.relationship('Image', backref='product', lazy=True, cascade='all, delete-orphan')

    def __repr__(self):
        return f'<Product {self.serial_number} - {self.product_name}>'

class Image(db.Model):
    __tablename__ = 'images'
    id = db.Column(db.Integer, primary_key=True)
    product_id = db.Column(db.Integer, db.ForeignKey('products.id', ondelete='CASCADE'), nullable=False)
    input_image_url = db.Column(db.Text, nullable=False)
    output_image_url = db.Column(db.Text)

    def __repr__(self):
        return f'<Image {self.id} for Product {self.product_id}>'
