// MongoDB Collection: orders
{
  "_id": ObjectId("..."),
  "order_id": "ORD-2024-001234",
  "customer": {
    "user_id": "user_12345",
    "email": "customer@example.com"
  },
  "items": [
    {
      "product_id": "550e8400-e29b-41d4-a716-446655440000",
      "sku": "LAPTOP001",
      "name": "Gaming Laptop Pro",
      "price": 1299.99,
      "quantity": 1
    }
  ],
  "pricing": {
    "subtotal": 1299.99,
    "tax": 104.00,
    "total": 1403.99
  },
  "payment": {
    "status": "completed", // pending, completed, failed
    "transaction_id": "txn_abc123xyz",
    "processed_at": ISODate("2024-08-04T10:30:00Z")
  },
  "status": "confirmed", // pending, processing, confirmed, cancelled
  "created_at": ISODate("2024-08-04T10:25:00Z"),
  "updated_at": ISODate("2024-08-04T10:30:00Z")
}

// Índices MongoDB
db.orders.createIndex({"order_id": 1}, {unique: true})
db.orders.createIndex({"customer.user_id": 1})
db.orders.createIndex({"status": 1})
db.orders.createIndex({"created_at": -1})