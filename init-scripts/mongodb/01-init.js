// Inicialización de MongoDB para el sistema de órdenes
// Este script se ejecuta automáticamente cuando se crea el contenedor

// Conectar a la base de datos
db = db.getSiblingDB('ecommerce_orders');

// Crear colección de órdenes con validación de schema
db.createCollection('orders');

// Crear índices para performance
db.orders.createIndex({ 'order_id': 1 }, { unique: true });
db.orders.createIndex({ 'customer.user_id': 1 });
db.orders.createIndex({ 'status': 1 });
db.orders.createIndex({ 'created_at': -1 });
db.orders.createIndex({ 'items.sku': 1 });
db.orders.createIndex({ 'payment.status': 1 });
db.orders.createIndex({ 'customer.user_id': 1, 'created_at': -1 });

// Índices para queries complejas
db.orders.createIndex({ 
  'customer.user_id': 1, 
  'status': 1, 
  'created_at': -1 
});

// Índice de texto para búsquedas
db.orders.createIndex({
  'order_id': 'text',
  'customer.email': 'text',
  'items.name': 'text'
});

// Insertar algunos datos de ejemplo para testing
const sampleOrders = [
  {
    order_id: 'ORD-2024-000001',
    customer: {
      user_id: 'user_demo_001',
      email: 'demo@example.com'
    },
    items: [
      {
        product_id: '550e8400-e29b-41d4-a716-446655440000',
        sku: 'LAPTOP001',
        name: 'Gaming Laptop Pro',
        price: 1299.99,
        quantity: 1
      }
    ],
    pricing: {
      subtotal: 1299.99,
      tax: 104.00,
      total: 1403.99
    },
    payment: {
      status: 'completed',
      transaction_id: 'txn_demo_001',
      processed_at: new Date()
    },
    status: 'confirmed',
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    order_id: 'ORD-2024-000002',
    customer: {
      user_id: 'user_demo_002',
      email: 'customer2@example.com'
    },
    items: [
      {
        product_id: '550e8400-e29b-41d4-a716-446655440001',
        sku: 'MOUSE001',
        name: 'Wireless Gaming Mouse',
        price: 79.99,
        quantity: 2
      },
      {
        product_id: '550e8400-e29b-41d4-a716-446655440002',
        sku: 'KEYBOARD001',
        name: 'Mechanical Gaming Keyboard',
        price: 149.99,
        quantity: 1
      }
    ],
    pricing: {
      subtotal: 309.97,
      tax: 24.80,
      total: 334.77
    },
    payment: {
      status: 'pending'
    },
    status: 'processing',
    created_at: new Date(Date.now() - 3600000), // 1 hora atrás
    updated_at: new Date()
  }
];

// Insertar datos de ejemplo
db.orders.insertMany(sampleOrders);

// Crear colección para eventos de auditoría (opcional)
db.createCollection('order_events');
db.order_events.createIndex({ 'order_id': 1, 'timestamp': -1 });
db.order_events.createIndex({ 'event_type': 1 });
db.order_events.createIndex({ 'timestamp': -1 });

print('MongoDB initialization completed successfully!');
print('Collections created: orders, order_events');
print('Sample data inserted: 2 orders');
print('Indexes created for optimal query performance');