# PASOS USADOS PARA LA RESPUESTA:

newgrp docker

 - PROBAR INVENTARIO Y PRODUCTOS (Postgres):
      - docker exec -it ecommerce_postgres psql -U postgres -d ecommerce_inventory
      - SELECT * FROM product
      - SELECT * FROM inventory

 - PROBAR ORDENES(Mongo):
      - docker exec -it ecommerce_mongodb mongosh -u admin -p admin123 --authenticationDatabase admin
      ### cambiar a la bd:
      - use ecommerce_orders;
      - db.orders.find().pretty();


 - VERIFICAR LOS TOPICS DE KAFKA: (verificado, ya existe):
      - docker exec -it ecommerce_kafka kafka-topics \
      --bootstrap-server kafka:29092 \
      --create --topic order-events \
      --partitions 3 --replication-factor 1

 - INSTALAR PROTO Y GENERAR EL ARCHIVO PY de order_events(Linux):
      - sudo apt install -y python3-protobuf python3-psycopg2 python3-pymongo python3-confluent-kafka
      - protoc -I=. --python_out=generated proto/order_events.proto

(Opcional, en el código ya está agregado este topic)
### CREAR TOPIC en caso de fallo silencioso
- docker exec ecommerce_kafka kafka-topics \
  --bootstrap-server localhost:9092 \
  --create --topic order-events \
  --partitions 3 \
  --replication-factor 1

# CORRER LOS COMANDOS DE PYTHON Y API

 - cd ordenes
 - source venv/bin/activate (iniciar entorno virtual para correr API)
 - uvicorn producer:app --reload (iniciar API)
 ### ENDPOINTS
 - POST: http://127.0.0.1:8000/orders (enviar una orden, cambiar id en caso de probar nueva orden):
     {
     "order_id": "ORD-TEST-005",
     "customer": {"user_id": "user_002", "email": "test2@gmail.com"},
     "items": [{"product_id": "65d7f44c-5620-48e4-ac6d-f615de1c67d8", "sku": "LAPTOP001", "name": "Laptop", "price": 1299.99, "quantity": 1}]
     }
 - GET: http://127.0.0.1:8000/orders (Ver todas las ordenes)
 - GET: http://127.0.0.1:8000/orders/{order_id} (ver orden especifica)
 # Correr el kafka para simular el pago, actualizar el pago y guardar la orden
 - python3 costumer.py (Procesa la orden, valida stock disponible y se agregó mensaje de fallo de pago en un 20% para probar los mensajes de error de pago, además se puso el bucle para aceptar hasta cinco ordenes)


# Descripción

Vas a construir un Sistema Básico de Procesamiento de Órdenes que maneje el flujo desde la creación hasta la confirmación.

Flujo: Validación → Kafka → Pago → Confirmación

## Contexto del Negocio
Una tienda online necesita procesar órdenes simples. Cada orden debe:

- Validar disponibilidad de inventario
- Procesar el pago de forma asíncrona
- Actualizar el inventario
- Confirmar la orden

## Flujo del Sistema
1. API REST recibe la orden
2. Validación inicial de datos e inventario
3. Publicar evento a Kafka para procesamiento asíncrono
4. Consumer de Kafka procesa la orden:
   - Simula procesamiento de pago
   - Actualiza inventario (PostgreSQL)
   - Guarda orden completa (MongoDB)

## Requisitos Técnicos
- Backend: Python o Go
- Bases de datos: PostgreSQL (inventario), MongoDB (órdenes)
- Message Queue: Kafka con protobuf
- Deployment: Docker

## Casos Edge a Manejar
- Inventario insuficiente
- Productos inexistentes
- Fallos de pago simulado
- Órdenes duplicadas (idempotencia)

## Arquitectura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │    MongoDB      │    │     Kafka       │
│   (Inventory)   │    │   (Orders)      │    │   (Events)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  Application    │
                    │  (REST API)     │
                    └─────────────────┘
```

## Servicios Incluidos

| Servicio | Puerto | Credenciales | Propósito |
|----------|--------|--------------|-----------|
| PostgreSQL | 5432 | postgres/postgres123 | Inventario y productos |
| MongoDB | 27017 | admin/admin123 | Órdenes completadas |
| Kafka | 9092 | - | Eventos asíncronos |

### Prerrequisitos
- Docker & Docker Compose
- Make (opcional)

### Levantamiento

```bash
docker compose up -d
make kafka-create-topics
```

### Verificar que todo esté funcionando

```bash
# Verificar estado de servicios
make status

# Ver información de conexión
make info
```

### Ver comandos

```bash
make help
```