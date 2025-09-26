from confluent_kafka import Consumer
import psycopg2
import pymongo
import random
from generated import order_events_pb2 as order_pb2
from dotenv import load_dotenv
import os

load_dotenv()

# Config Kafka
consumer = Consumer({
    'bootstrap.servers': os.getenv("KAFKA_BOOTSTRAP_SERVERS"),
    'group.id': os.getenv("KAFKA_GROUP_ID"),
    'auto.offset.reset': 'earliest'
})
consumer.subscribe([os.getenv("KAFKA_TOPIC")])

# Configurar Postgres
pg_conn = psycopg2.connect(
    dbname=os.getenv("POSTGRES_DB"),
    user=os.getenv("POSTGRES_USER"),
    password=os.getenv("POSTGRES_PASSWORD"),
    host=os.getenv("POSTGRES_HOST"),
    port=os.getenv("POSTGRES_PORT")
)
pg_conn.autocommit = True
pg_cur = pg_conn.cursor()

# Configurar MongoDB
mongo_client = pymongo.MongoClient(os.getenv("MONGO_URI"))
mongo_db = mongo_client[os.getenv("MONGO_DB")]
orders = mongo_db["orders"]

print("Esperando mensajes en Kafka...")

MAX_MESSAGES = 5 # Caso para que acepte hasta cinco ordenes enviadas
processed = 0 

while processed < MAX_MESSAGES:
    msg = consumer.poll(1.0)
    if msg is None:
        continue
    if msg.error():
        print("Error:", msg.error())
        continue

    event = order_pb2.OrderEvent()
    event.ParseFromString(msg.value())

    if event.event_type == order_pb2.ORDER_CREATED:
        print(f"Procesando orden {event.order_id}")
        processed += 1
        # Verificar si ya existe en Mongo
        if orders.find_one({"order_id": event.order_id}):
            print(f"Orden {event.order_id} ya procesada, ignorando.")
            consumer.commit(msg)
            continue

        # Verificar inventario en Postgres
        sku = event.order_created.items[0].sku
        quantity = event.order_created.items[0].quantity

        pg_cur.execute("SELECT i.id, i.available_quantity FROM inventory i "
                       "JOIN product p ON i.product_id = p.id WHERE p.sku = %s", (sku,))
        result = pg_cur.fetchone()

        if not result:
            print(f"Producto {sku} inexistente")
            orders.insert_one({
                "order_id": event.order_id,
                "status": "failed",
                "reason": "INVALID_PRODUCT"
            })
            consumer.commit(msg)
            continue

        if result[1] < quantity:
            print(f"Inventario insuficiente para {sku}")
            orders.insert_one({
                "order_id": event.order_id,
                "status": "failed",
                "reason": "INSUFFICIENT_INVENTORY"
            })
            consumer.commit(msg)
            continue

         # Simulación de pago (80% éxito, 20% fallo)
        if random.random() < 0.8:
            payment_status = "completed"
            tx_id = f"TX-{random.randint(1000,9999)}"
            print(f"Pago aprobado (tx: {tx_id})")
        else:
            payment_status = "failed"
            print("Pago rechazado")
            orders.insert_one({
                "order_id": event.order_id,
                "status": "failed",
                "reason": "PAYMENT_DECLINED"
            })
            consumer.commit(msg)
            continue

        # Actualizar inventario
        pg_cur.execute("UPDATE inventory SET available_quantity = available_quantity - %s WHERE id = %s",
                       (quantity, result[0]))

        # Insertar orden en Mongo
        order_doc = {
            "order_id": event.order_id,
            "customer": {
                "user_id": event.order_created.customer.user_id,
                "email": event.order_created.customer.email,
            },
            "items": [{
                "product_id": event.order_created.items[0].product_id,
                "sku": sku,
                "name": event.order_created.items[0].name,
                "price": event.order_created.items[0].price,
                "quantity": quantity,
            }],
            "payment": {"status": payment_status, "transaction_id": tx_id},
            "status": "confirmed"
        }
        orders.insert_one(order_doc)

        print(f"Orden {event.order_id} confirmada y guardada en MongoDB")

# Cerrar las conexiones
consumer.close()
pg_conn.close()
mongo_client.close()


