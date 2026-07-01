# Informe Técnico del Proyecto DevOps - Despacho Dashboard

## 1. Resumen del Proyecto

Aplicación web para gestión de despachos y ventas. Consta de un frontend React (Vite) y un backend Spring Boot 3, desplegados en AWS ECS Fargate con un pipeline CI/CD automatizado via GitHub Actions.

---

## 2. Infraestructura AWS (Console + CLI)

### 2.1 VPC y Redes
- **VPC dedicada** creada desde la consola AWS.
- **Subredes públicas:** Para el ALB (Application Load Balancer).
- **Subredes privadas:** Para los contenedores ECS Fargate.
- **Región:** `us-east-1` (Norte de Virginia).

### 2.2 Security Groups (3 grupos restrictivos)

| Grupo | Propósito | Reglas Inbound | Reglas Outbound |
|---|---|---|---|
| `sg-alb` | Application Load Balancer | HTTP (80) desde `0.0.0.0/0` | Todo tráfico |
| `sg-frontend` | Contenedores Frontend | TCP 80 solo desde `sg-alb` | Todo tráfico |
| `sg-backend` | Contenedores Backend | TCP 3000 solo desde `sg-frontend` | Todo tráfico |

Se agregó una regla adicional en `sg-backend` para permitir tráfico desde `sg-alb` en puerto 3000 (para health checks del ALB hacia el backend).

### 2.3 IAM
- Cuenta académica AWS Academy Learner Lab.
- No se permite crear roles IAM (`iam:CreateRole` denegado).
- Se reutiliza el rol `LabRole` como `executionRoleArn` y `taskRoleArn` en las Task Definitions.

### 2.4 Application Load Balancer (ALB)
- **Nombre:** `alb-ep3`
- **DNS:** `alb-devops-1779173539.us-east-1.elb.amazonaws.com`
- **Scheme:** Internet-facing
- **Listener:** HTTP puerto 80
- **Regla por defecto:** Reenviar a `tg-frontend` (puerto 80)
- **Regla adicional (path-based):** Si el path empieza con `/api/*`, reenviar a `tg-backend` (puerto 3000)

### 2.5 Target Groups

| Target Group | Puerto | Health Check | VPC |
|---|---|---|---|
| `tg-frontend` | 80 | HTTP `/` | Misma VPC |
| `tg-backend` | 3000 | HTTP `/api/v1/despachos` (timeout 30s, interval 120s) | Misma VPC |

La configuración de health check del backend se ajustó con timeout de 30s e intervalo de 120s para manejar el lento inicio de Spring Boot (~76s).

### 2.6 ECS (Elastic Container Service)
- **Cluster:** `cluster-ep3` (creado via CLI, solo Fargate)
- **Servicios:**
  - `service-frontend` — 1-3 tareas, asociado a `tg-frontend` (puerto 80)
  - `service-backend` — 1-3 tareas, asociado a `tg-backend` (puerto 3000)

### 2.7 ECR (Elastic Container Registry)
| Repositorio | Imagen |
|---|---|
| `devops3` | Frontend (nginx, puerto 80) |
| `devops3back` | Backend (Spring Boot, puerto 3000) |

### 2.8 Autoscaling
- **Métrica:** CPU promedio del servicio
- **Target:** 50% de utilización de CPU
- **Cooldown:** 60s scale-out, 60s scale-in
- **Capacidad:** Mínimo 1 tarea, Máximo 3 tareas
- **Aplicado a:** Ambos servicios (`service-frontend`, `service-backend`)

### 2.9 CloudWatch Logs
- Log group: `/ecs/task-frontend` — prefijo `frontend`
- Log group: `/ecs/task-backend` — prefijo `backend`

---

## 3. Aplicaciones

### 3.1 Frontend (React + Vite + Tailwind)
- **Framework:** React 18 con Vite + SWC
- **Estilos:** Tailwind CSS
- **Librerías:** axios, react-router-dom, react-hook-form, sweetalert2
- **Puerto:** 80 (nginx)
- **Dockerfile:** Multi-stage (Node 20 build → nginx:alpine runtime)
- **API_URL:** Inyectado como build arg (`VITE_API_URL`), apunta al ALB

### 3.2 Backend (Spring Boot 3 + Java 17)
- **Framework:** Spring Boot 3.4.4 con Java 17
- **Base de datos:** H2 en memoria (testdb), con schema auto-generado via JPA
- **Puerto:** 3000
- **API:** Swagger disponible en `/swagger-ui.html`
- **Endpoints REST:**
  - `GET/POST /api/v1/ventas`
  - `PUT /api/v1/ventas/{id}`
  - `GET/POST /api/v1/despachos`
  - `PUT /api/v1/despachos/{id}`
  - `DELETE /api/v1/despachos/{id}`
- **H2 Console:** `/h2-console`
- **Dockerfile:** Multi-stage (Maven 3.9 + Temurin 17 build → JRE 17 Alpine runtime)

---

## 4. CI/CD (GitHub Actions)

**Archivo:** `.github/workflows/deploy.yml`

**Trigger:** Push a `main` o `workflow_dispatch`

**Jobs paralelos:**
1. **deploy-frontend:** Build → Push a ECR (`devops3`) → Deploy a ECS (`service-frontend`)
2. **deploy-backend:** Build → Push a ECR (`devops3back`) → Deploy a ECS (`service-backend`)

**Variables de entorno del pipeline:**
- `VITE_API_URL=http://alb-devops-1779173539.us-east-1.elb.amazonaws.com`

**Secrets requeridos:**
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

---

## 5. Problemas Encontrados y Soluciones

| Problema | Solución |
|---|---|
| Backend usaba MySQL pero no había RDS | Cambiar a H2 en memoria |
| Frontend nginx no resolvía el backend | Agregar `resolver` en `nginx.conf` |
| No había path-based routing en ALB | Agregar listener rule para `/api/*` → tg-backend |
| Health check del backend fallaba por timeout | Aumentar timeout a 30s, intervalo a 120s |
| Frontend enviaba `entregado` en vez de `despachado` | Corregir field name en `FormDespacho.jsx` |
| Tabla de despachos usaba `despacho.entregado` | Cambiar a `despacho.despachado` |
| Backend sobrescribía campos con null en update | Modificar `updateDespacho` para solo actualizar campos no nulos |
| Spring Boot tomaba ~76s en iniciar | Aumentar health check timeout/interval + TCP health check |
| Servicio backend no tenía LB asociado | Configurar `loadBalancers` en el servicio ECS |
| No había UI para crear ventas | Agregar `FormVenta` con botón "+ Nueva Orden de Compra" |
| Sidebar (Usuarios/Productos/Config) no funcionaba | Son placeholders estáticos del código original |

---

## 6. Arquitectura Final

```
Internet
    |
    v
[ALB: alb-ep3] (Internet-facing, HTTP 80)
    | SG: sg-alb (inbound: 0.0.0.0/0:80)
    | Regla por defecto: → tg-frontend
    | Regla path /api/*: → tg-backend
    |
    ├──→ [tg-frontend:80] → service-frontend (Fargate, 1-3 tareas)
    |       SG: sg-frontend (inbound: solo desde sg-alb:80)
    |       Contenedor: nginx (puerto 80)
    |       Imagen: devops3:latest
    |
    └──→ [tg-backend:3000] → service-backend (Fargate, 1-3 tareas)
            SG: sg-backend (inbound: desde sg-frontend:3000 y sg-alb:3000)
            Contenedor: Spring Boot (puerto 3000)
            Imagen: devops3back:latest
            BD: H2 en memoria (ephemeral)
```

---

## 7. Comandos CLI Utilizados

### Crear cluster ECS
```
aws ecs create-cluster --cluster-name cluster-ep3
```

### Registrar task definitions
```
aws ecs register-task-definition --cli-input-json file://aws/task-definition-frontend.json
aws ecs register-task-definition --cli-input-json file://aws/task-definition-backend.json
```

### Crear servicios ECS
```
aws ecs create-service --cluster cluster-ep3 --service-name service-frontend ...
aws ecs create-service --cluster cluster-ep3 --service-name service-backend ...
```

### Build y push local
```
docker build --build-arg VITE_API_URL=http://alb-devops-1779173539.us-east-1.elb.amazonaws.com -t <ecr-registry>/devops3:latest ./proyecto semestral/front_despacho
docker build -t <ecr-registry>/devops3back:latest ./proyecto semestral/backend
docker push <ecr-registry>/devops3:latest
docker push <ecr-registry>/devops3back:latest
```

### Autoscaling
```
aws application-autoscaling register-scalable-target --service-namespace ecs --resource-id service/cluster-ep3/service-frontend --scalable-dimension ecs:service:DesiredCount --min-capacity 1 --max-capacity 3
aws application-autoscaling put-scaling-policy --service-namespace ecs --resource-id service/cluster-ep3/service-frontend --scalable-dimension ecs:service:DesiredCount --policy-name cpu-target-frontend --policy-type TargetTrackingScaling --target-tracking-scaling-policy-configuration file://aws/scaling-policy-frontend.json
```

### Forzar redeploy
```
aws ecs update-service --cluster cluster-ep3 --service service-frontend --force-new-deployment
aws ecs update-service --cluster cluster-ep3 --service service-backend --force-new-deployment
```

### ALB Listener Rule (path-based routing)
```
aws elbv2 create-rule --listener-arn <arn> --priority 10 --conditions Field=path-pattern,Values=/api/* --actions Type=forward,TargetGroupArn=<tg-backend-arn>
```

---

## 8. URLs de Acceso

| Recurso | URL |
|---|---|
| Aplicación | http://alb-devops-1779173539.us-east-1.elb.amazonaws.com |
| API Ventas | http://alb-devops-1779173539.us-east-1.elb.amazonaws.com/api/v1/ventas |
| API Despachos | http://alb-devops-1779173539.us-east-1.elb.amazonaws.com/api/v1/despachos |
| Swagger UI | http://alb-devops-1779173539.us-east-1.elb.amazonaws.com/api/v1/swagger-ui.html |
| H2 Console | http://alb-devops-1779173539.us-east-1.elb.amazonaws.com/api/v1/h2-console |
