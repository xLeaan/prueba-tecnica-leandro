from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
from confluent_kafka import Producer
from google.protobuf.timestamp_pb2 import Timestamp
from generated import order_events_pb2 as order_pb2
import uuid
import pymongo

# ------------------------
# Configuración MongoDB
# ------------------------
MONGO_URI = "mongodb://admin:admin123@localhost:27017/"
MONGO_DB = "ecommerce_orders"

mongo_client = pymongo.MongoClient(MONGO_URI)
mongo_db = mongo_client[MONGO_DB]
orders_collection = mongo_db["orders"]

# ------------------------
# Configuración Kafka
# ------------------------
producer = Producer({'bootstrap.servers': 'localhost:9092'})

# ------------------------
# FastAPI
# ------------------------
app = FastAPI(title="E-commerce Orders API")

# ------------------------
# Modelos Pydantic
# ------------------------
class OrderItem(BaseModel):
    product_id: str
    sku: str
    name: str
    price: float
    quantity: int

class Customer(BaseModel):
    user_id: str
    email: str

class Order(BaseModel):
    order_id: str
    customer: Customer
    items: List[OrderItem]

# ------------------------
# Endpoints
# ------------------------
@app.post("/orders")
def create_order(order: Order):
    # Crear evento Protobuf
    event = order_pb2.OrderEvent()
    event.event_id = str(uuid.uuid4())
    event.order_id = order.order_id
    event.event_type = order_pb2.ORDER_CREATED

    ts = Timestamp()
    ts.GetCurrentTime()
    event.timestamp.CopyFrom(ts)

    order_created = order_pb2.OrderCreated()
    order_created.order_id = order.order_id
    order_created.customer.user_id = order.customer.user_id
    order_created.customer.email = order.customer.email

    for item in order.items:
        i = order_created.items.add()
        i.product_id = item.product_id
        i.sku = item.sku
        i.name = item.name
        i.price = item.price
        i.quantity = item.quantity

    event.order_created.CopyFrom(order_created)

    # Enviar evento a Kafka
    producer.produce("order-events", value=event.SerializeToString())
    producer.flush()

    return {"status": "ok", "order_id": order.order_id}

@app.get("/orders")
def list_orders():
    orders_cursor = orders_collection.find().sort("created_at", -1)
    orders_list = []
    for o in orders_cursor:
        o["_id"] = str(o["_id"])
        orders_list.append(o)
    return orders_list

@app.get("/orders/{order_id}")
def get_order(order_id: str):
    order = orders_collection.find_one({"order_id": order_id})
    if not order:
        raise HTTPException(status_code=404, detail="Order not found")
    order["_id"] = str(order["_id"])
    return order
