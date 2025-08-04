# Makefile para el sistema de e-commerce
# Comandos útiles para desarrollo y testing

.PHONY: help up down restart logs clean test-db kafka-topics status

# Variables
COMPOSE_FILE = docker-compose.yml
PROJECT_NAME = ecommerce

help: ## Mostrar ayuda
	@echo "Comandos disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Levantar todos los servicios
	docker compose -f $(COMPOSE_FILE) up -d
	@echo "Esperando que los servicios estén listos..."
	@sleep 10
	@make status

down: ## Detener todos los servicios
	docker compose -f $(COMPOSE_FILE) down

restart: ## Reiniciar todos los servicios
	docker compose -f $(COMPOSE_FILE) restart

logs: ## Ver logs de todos los servicios
	docker compose -f $(COMPOSE_FILE) logs -f

logs-app: ## Ver logs solo de la aplicación (cuando esté disponible)
	docker compose -f $(COMPOSE_FILE) logs -f app

logs-kafka: ## Ver logs de Kafka
	docker compose -f $(COMPOSE_FILE) logs -f kafka

logs-postgres: ## Ver logs de PostgreSQL
	docker compose -f $(COMPOSE_FILE) logs -f postgres

logs-mongodb: ## Ver logs de MongoDB
	docker compose -f $(COMPOSE_FILE) logs -f mongodb

status: ## Verificar estado de todos los servicios
	@echo "=== Estado de los servicios ==="
	docker compose -f $(COMPOSE_FILE) ps
	@echo ""
	@echo "=== Health checks ==="
	@docker ps --format "table {{.Names}}\t{{.Status}}" | grep ecommerce

clean: ## Limpiar todo (contenedores, volúmenes, redes)
	docker compose -f $(COMPOSE_FILE) down -v --remove-orphans
	docker system prune -f

clean-all: ## Limpiar todo incluyendo imágenes
	docker compose -f $(COMPOSE_FILE) down -v --remove-orphans --rmi all
	docker system prune -af

# Comandos específicos para bases de datos
test-postgres: ## Probar conexión a PostgreSQL
	@echo "Probando conexión a PostgreSQL..."
	docker exec ecommerce_postgres psql -U postgres -d ecommerce_inventory -c "SELECT 'PostgreSQL conectado correctamente' as status;"

test-mongodb: ## Probar conexión a MongoDB
	@echo "Probando conexión a MongoDB..."
	docker exec ecommerce_mongodb mongosh --eval "db.adminCommand('ping')" ecommerce_orders

postgres-shell: ## Abrir shell de PostgreSQL
	docker exec -it ecommerce_postgres psql -U postgres -d ecommerce_inventory

mongodb-shell: ## Abrir shell de MongoDB
	docker exec -it ecommerce_mongodb mongosh ecommerce_orders

# Comandos específicos para Kafka
kafka-topics: ## Listar topics de Kafka
	docker exec ecommerce_kafka kafka-topics --bootstrap-server localhost:9092 --list

kafka-create-topics: ## Crear topics necesarios para la aplicación
	@echo "Creando topics de Kafka..."
	docker exec ecommerce_kafka kafka-topics --bootstrap-server localhost:9092 --create --topic order-events --partitions 3 --replication-factor 1 --if-not-exists
	docker exec ecommerce_kafka kafka-topics --bootstrap-server localhost:9092 --create --topic payment-events --partitions 3 --replication-factor 1 --if-not-exists
	docker exec ecommerce_kafka kafka-topics --bootstrap-server localhost:9092 --create --topic inventory-events --partitions 3 --replication-factor 1 --if-not-exists
	@echo "Topics creados exitosamente"

kafka-describe-topic: ## Describir un topic específico (uso: make kafka-describe-topic TOPIC=order-events)
	docker exec ecommerce_kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic $(TOPIC)

kafka-console-consumer: ## Consumir mensajes de un topic (uso: make kafka-console-consumer TOPIC=order-events)
	docker exec -it ecommerce_kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic $(TOPIC) --from-beginning

kafka-console-producer: ## Producir mensajes a un topic (uso: make kafka-console-producer TOPIC=order-events)
	docker exec -it ecommerce_kafka kafka-console-producer --bootstrap-server localhost:9092 --topic $(TOPIC)

# Comandos para monitoreo
monitor: ## Mostrar recursos utilizados por los contenedores
	docker stats $(shell docker compose -f $(COMPOSE_FILE) ps -q)

# Información útil
info: ## Mostrar información de conexión
	@echo "=== Información de Conexión ==="
	@echo ""
	@echo "PostgreSQL:"
	@echo "  Host: localhost:5432"
	@echo "  Database: ecommerce_inventory"
	@echo "  User: postgres"
	@echo "  Password: postgres123"
	@echo ""
	@echo "MongoDB:"
	@echo "  Host: localhost:27017"
	@echo "  Database: ecommerce_orders"
	@echo "  User: admin"
	@echo "  Password: admin123"
	@echo ""
	@echo "Kafka:"
	@echo "  Brokers: localhost:9092"
	@echo "  UI: http://localhost:8080"
	@echo ""
	@echo "=== URLs de Conexión ==="
	@echo "PostgreSQL URI: postgresql://postgres:postgres123@localhost:5432/ecommerce_inventory"
	@echo "MongoDB URI: mongodb://admin:admin123@localhost:27017/ecommerce_orders?authSource=admin"