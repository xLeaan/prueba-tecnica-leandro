-- Inicialización de base de datos PostgreSQL para el sistema de inventario

-- Crear extensión para UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Tabla de productos
CREATE TABLE IF NOT EXISTS product (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de inventario
CREATE TABLE IF NOT EXISTS inventory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES product(id) ON DELETE CASCADE,
    available_quantity INTEGER NOT NULL CHECK (available_quantity >= 0),
    reserved_quantity INTEGER DEFAULT 0 CHECK (reserved_quantity >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(product_id)
);

-- Función para actualizar timestamp automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar updated_at en product
CREATE TRIGGER update_product_updated_at 
    BEFORE UPDATE ON product 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Función para actualizar last_updated en inventory automáticamente
CREATE OR REPLACE FUNCTION update_inventory_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para actualizar last_updated en inventory
CREATE TRIGGER update_inventory_timestamp 
    BEFORE UPDATE ON inventory 
    FOR EACH ROW EXECUTE FUNCTION update_inventory_timestamp();

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_product_sku ON product(sku);
CREATE INDEX IF NOT EXISTS idx_product_name ON product USING gin(to_tsvector('english', name));
CREATE INDEX IF NOT EXISTS idx_inventory_product_id ON inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_available ON inventory(available_quantity) WHERE available_quantity > 0;

-- Insertar datos de ejemplo
INSERT INTO product (sku, name, price) VALUES
('LAPTOP001', 'Gaming Laptop Pro', 1299.99),
('MOUSE001', 'Wireless Gaming Mouse', 79.99),
('CHAIR001', 'Ergonomic Office Chair', 299.99),
('KEYBOARD001', 'Mechanical Gaming Keyboard', 149.99),
('MONITOR001', '27" 4K Gaming Monitor', 449.99)
ON CONFLICT (sku) DO NOTHING;

-- Insertar inventario inicial
INSERT INTO inventory (product_id, available_quantity) 
SELECT id, 
    CASE 
        WHEN sku = 'LAPTOP001' THEN 15
        WHEN sku = 'MOUSE001' THEN 50
        WHEN sku = 'CHAIR001' THEN 25
        WHEN sku = 'KEYBOARD001' THEN 30
        WHEN sku = 'MONITOR001' THEN 20
    END as available_quantity
FROM product
ON CONFLICT (product_id) DO NOTHING;

