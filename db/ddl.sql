-- DDL para PostgreSQL
CREATE DATABASE ecommerce_inventory;

-- Tabla de productos
CREATE TABLE products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de inventario
CREATE TABLE inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    available_quantity INTEGER NOT NULL CHECK (available_quantity >= 0),
    reserved_quantity INTEGER DEFAULT 0 CHECK (reserved_quantity >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id)
);

-- Índices
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_inventory_product_id ON inventory(product_id);

-- Datos de ejemplo
INSERT INTO products (sku, name, price) VALUES
('LAPTOP001', 'Gaming Laptop Pro', 1299.99),
('MOUSE001', 'Wireless Gaming Mouse', 79.99),
('CHAIR001', 'Ergonomic Office Chair', 299.99);

INSERT INTO inventory (product_id, available_quantity) VALUES
((SELECT id FROM products WHERE sku = 'LAPTOP001'), 15),
((SELECT id FROM products WHERE sku = 'MOUSE001'), 50),
((SELECT id FROM products WHERE sku = 'CHAIR001'), 25);