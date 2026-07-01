# Despacho Dashboard - DevOps Project

Aplicación web para gestión de despachos y ventas desplegada en AWS ECS Fargate con CI/CD via GitHub Actions.

## Requisitos

- Node.js 20+
- Java 17+ (Maven 3.9+)
- Docker Desktop
- AWS CLI configurado con credenciales
- Cuenta AWS con ECR, ECS, ALB, VPC configurados

---

## Desarrollo Local

### 1. Clonar el repositorio

```bash
git clone https://github.com/vichomnz/devops3.git
cd devops3
```

### 2. Backend

```bash
cd "proyecto semestral/backend"
mvn clean package -DskipTests
java -jar target/backend-unificado-1.0.0.jar
```

El backend corre en `http://localhost:3000`. Usa H2 en memoria, schema auto-creado.

**Endpoints:**
- `GET/POST /api/v1/ventas`
- `GET/POST /api/v1/despachos`
- `PUT /api/v1/ventas/{id}`
- `PUT /api/v1/despachos/{id}`
- `DELETE /api/v1/despachos/{id}`
- Swagger: `http://localhost:3000/swagger-ui.html`
- H2 Console: `http://localhost:3000/h2-console`

### 3. Frontend

```bash
cd "proyecto semestral/front_despacho"
npm install
npm run dev
```

El frontend corre en `http://localhost:5173`. Las llamadas `/api/*` se redirigen al backend (`http://localhost:3000/api/*`) via proxy de Vite.

**Para producción local:**
```bash
VITE_API_URL=http://localhost:3000 npm run build
# Sirve la carpeta dist/ con cualquier servidor estático
```

---

## Despliegue en AWS

### Infraestructura previa requerida (crear manualmente en AWS Console o CLI)

1. **VPC** con subredes públicas y privadas
2. **3 Security Groups:** `sg-alb`, `sg-frontend`, `sg-backend`
   - `sg-alb`: HTTP 80 desde `0.0.0.0/0`
   - `sg-frontend`: TCP 80 desde `sg-alb`
   - `sg-backend`: TCP 3000 desde `sg-frontend` y `sg-alb`
3. **ALB** (`alb-ep3`) internet-facing, HTTP 80
4. **Target Groups:**
   - `tg-frontend`: puerto 80, health check HTTP `/`
   - `tg-backend`: puerto 3000, health check HTTP `/api/v1/despachos` (timeout 30s, interval 120s)
5. **Regla path-based** en ALB: `/api/*` → `tg-backend`, prioridad 10
6. **Cluster ECS** (`cluster-ep3`) — solo Fargate
7. **2 repositorios ECR:** `devops3` y `devops3back`
8. **Rol IAM** `LabRole` (o equivalente) con permisos ECR, ECS, CloudWatch Logs

### Construir y subir imágenes manualmente

```bash
# Login a ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-east-1.amazonaws.com

# Frontend
docker build \
  --build-arg VITE_API_URL=http://alb-devops-1779173539.us-east-1.elb.amazonaws.com \
  -t <account>.dkr.ecr.us-east-1.amazonaws.com/devops3:latest \
  "./proyecto semestral/front_despacho"
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/devops3:latest

# Backend
docker build \
  -t <account>.dkr.ecr.us-east-1.amazonaws.com/devops3back:latest \
  "./proyecto semestral/backend"
docker push <account>.dkr.ecr.us-east-1.amazonaws.com/devops3back:latest
```

### Registrar task definitions y crear servicios

```bash
# Task definitions
aws ecs register-task-definition --cli-input-json file://aws/task-definition-frontend.json
aws ecs register-task-definition --cli-input-json file://aws/task-definition-backend.json

# Servicios
aws ecs create-service --cluster cluster-ep3 --service-name service-frontend \
  --task-definition task-frontend --desired-count 1 --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<subnets-privadas>],securityGroups=[sg-frontend],assignPublicIp=DISABLED}" \
  --load-balancers "targetGroupArn=<tg-frontend-arn>,containerName=frontend,containerPort=80"

aws ecs create-service --cluster cluster-ep3 --service-name service-backend \
  --task-definition task-backend --desired-count 1 --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<subnets-privadas>],securityGroups=[sg-backend],assignPublicIp=DISABLED}" \
  --load-balancers "targetGroupArn=<tg-backend-arn>,containerName=backend,containerPort=3000"
```

### Configurar autoscaling

```bash
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/cluster-ep3/service-frontend \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 1 --max-capacity 3

aws application-autoscaling put-scaling-policy \
  --service-namespace ecs \
  --resource-id service/cluster-ep3/service-frontend \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-name cpu-target-frontend \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://aws/scaling-policy-frontend.json

# Repetir para service-backend con policy-name cpu-target-backend
```

### Forzar redeploy

```bash
aws ecs update-service --cluster cluster-ep3 --service service-frontend --force-new-deployment
aws ecs update-service --cluster cluster-ep3 --service service-backend --force-new-deployment
```

---

## CI/CD (GitHub Actions)

El pipeline se activa automáticamente al hacer push a `main`.

**Secrets requeridos en GitHub:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

**Variables de entorno en el pipeline:**
- `VITE_API_URL=http://alb-devops-1779173539.us-east-1.elb.amazonaws.com`

---

## Estructura del Proyecto

```
devops3/
├── .github/workflows/deploy.yml    # CI/CD pipeline
├── aws/
│   ├── task-definition-frontend.json
│   ├── task-definition-backend.json
│   ├── scaling-policy-frontend.json
│   └── scaling-policy-backend.json
├── scripts/
│   ├── build-and-push.ps1
│   ├── deploy-ecs.ps1
│   └── configure-autoscaling.ps1
├── proyecto semestral/
│   ├── front_despacho/              # React + Vite
│   │   ├── Dockerfile
│   │   ├── nginx.conf
│   │   └── src/
│   └── backend/                     # Spring Boot 3
│       ├── Dockerfile
│       ├── pom.xml
│       └── src/
├── documento.md                     # Informe técnico detallado
└── README.md
```

---

## Funcionalidades de la App

1. **Nueva Orden de Compra** — formulario para crear ventas
2. **Consultar Ordenes de compra** — tabla de ventas con botón "Generar Despacho"
3. **Revisar Ordenes de despacho** — tabla de despachos con botón "Cerrar Despacho"

---

## URLs de Producción

| Recurso | URL |
|---|---|
| App | http://alb-devops-1779173539.us-east-1.elb.amazonaws.com |
| API Ventas | http://alb-devops-1779173539.us-east-1.elb.amazonaws.com/api/v1/ventas |
| API Despachos | http://alb-devops-1779173539.us-east-1.elb.amazonaws.com/api/v1/despachos |
