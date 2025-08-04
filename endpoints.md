# API Endpoints y Ejemplos de Uso (Simplificado)

## Base URL
```
http://localhost:8080/api/v1
```

## 1. Health Check
**GET** `/health`

```bash
curl -X GET http://localhost:8080/api/v1/health
```

**Respuesta esperada:**
```json
{
  "status": "healthy",
  "timestamp": "2024-08-04T10:30:00Z"
}
```

---

## 2. Obtener Productos
**GET** `/products`

```bash
# Obtener todos los productos
curl -X GET http://localhost:8080/api/v1/products

# Buscar por SKU específico
curl -X GET "http://localhost:8080/api/v1/products?sku=LAPTOP001"
```

**Respuesta esperada:**
```json
{
  "products": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "sku": "LAPTOP001",
      "name": "Gaming Laptop Pro",
      "price": 1299.99,
      "available_quantity": 15
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "sku": "MOUSE001",
      "name": "Wireless Gaming Mouse",
      "price": 79.99,
      "available_quantity": 50
    }
  ]
}
```

---

## 3. Verificar Inventario
**GET** `/products/{sku}/inventory`

```bash
curl -X GET http://localhost:8080/api/v1/products/LAPTOP001/inventory
```

**Respuesta esperada:**
```json
{
  "sku": "LAPTOP001",
  "product_name": "Gaming Laptop Pro",
  "available_quantity": 15,
  "reserved_quantity": 3
}
```

---

## 4. Crear Orden
**POST** `/orders`

```bash
curl -X POST http://localhost:8080/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "user_id": "user_12345",
      "email": "customer@example.com"
    },
    "items": [
      {
        "sku": "LAPTOP001",
        "quantity": 1
      },
      {
        "sku": "MOUSE001",
        "quantity": 2
      }
    ]
  }'
```

**Respuesta esperada:**
```json
{
  "order_id": "ORD-2024-001234",
  "status": "pending",
  "message": "Order created successfully and queued for processing",
  "estimated_total": 1459.97,
  "created_at": "2024-08-04T10:25:00Z"
}
```

---

## 5. Consultar Estado de Orden
**GET** `/orders/{order_id}`

```bash
curl -X GET http://localhost:8080/api/v1/orders/ORD-2024-001234
```

**Respuesta esperada:**
```json
{
  "order_id": "ORD-2024-001234",
  "status": "confirmed",
  "customer": {
    "user_id": "user_12345",
    "email": "customer@example.com"
  },
  "items": [
    {
      "sku": "LAPTOP001",
      "name": "Gaming Laptop Pro",
      "price": 1299.99,
      "quantity": 1
    },
    {
      "sku": "MOUSE001", 
      "name": "Wireless Gaming Mouse",
      "price": 79.99,
      "quantity": 2
    }
  ],
  "pricing": {
    "subtotal": 1459.97,
    "tax": 116.80,
    "total": 1576.77
  },
  "payment": {
    "status": "completed",
    "transaction_id": "txn_abc123xyz"
  },
  "created_at": "2024-08-04T10:25:00Z",
  "updated_at": "2024-08-04T10:30:00Z"
}
```

---

## 6. Obtener Órdenes por Usuario
**GET** `/users/{user_id}/orders`

```bash
curl -X GET http://localhost:8080/api/v1/users/user_12345/orders

# Con paginación
curl -X GET "http://localhost:8080/api/v1/users/user_12345/orders?page=1&limit=10"
```

**Respuesta esperada:**
```json
{
  "orders": [
    {
      "order_id": "ORD-2024-001234",
      "status": "confirmed",
      "total": 1576.77,
      "created_at": "2024-08-04T10:25:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 1,
    "has_more": false
  }
}
```

---

## Casos de Error Comunes

### Error: Inventario insuficiente
```bash
curl -X POST http://localhost:8080/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {"user_id": "user_12345", "email": "test@example.com"},
    "items": [{"sku": "LAPTOP001", "quantity": 100}]
  }'
```

**Respuesta:**
```json
{
  "error": "insufficient_inventory",
  "message": "Not enough inventory for LAPTOP001. Available: 15, Requested: 100",
  "code": 400
}
```

### Error: Producto no encontrado
```bash
curl -X POST http://localhost:8080/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {"user_id": "user_12345", "email": "test@example.com"},
    "items": [{"sku": "INVALID001", "quantity": 1}]
  }'
```

**Respuesta:**
```json
{
  "error": "product_not_found",
  "message": "Product with SKU INVALID001 not found",
  "code": 404
}
```

### Error: Fallo de pago (simulado)
```bash
# El sistema simula fallos de pago aleatoriamente para testing
```

**Respuesta cuando falla:**
```json
{
  "order_id": "ORD-2024-001235",
  "status": "failed",
  "error": "payment_failed",
  "message": "Payment processing failed. Inventory has been released.",
  "created_at": "2024-08-04T10:25:00Z"
}
```