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