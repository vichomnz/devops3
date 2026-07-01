# Contexto de Infraestructura AWS - Evaluación Parcial N°3 (DevOps)

## Estado Actual del Proyecto
Se ha completado la configuración de la infraestructura base en AWS utilizando la consola y AWS CLI. El entorno está preparado para recibir contenedores en ECS bajo el modelo AWS Fargate. Aún no hay código ni archivos `Dockerfile` creados.

## Detalles de la Infraestructura Creada

### 1. Redes (VPC y Subredes)
* Se creó una VPC dedicada para el proyecto.
* Se configuraron subredes públicas (para el Balanceador de Carga) y subredes privadas (para los contenedores).

### 2. Security Groups (Grupos de Seguridad)
Se implementó una arquitectura de red restrictiva con 3 Security Groups:
* **`sg-alb` (Application Load Balancer):**
  * Inbound: HTTP (Puerto 80) desde `0.0.0.0/0`.
  * Outbound: Todo el tráfico hacia `0.0.0.0/0`.
* **`sg-frontend` (Contenedores ECS Front):**
  * Inbound: TCP Personalizado (Puerto 80) permitiendo tráfico SOLO desde el ID de `sg-alb`.
  * Outbound: Todo el tráfico hacia `0.0.0.0/0`.
* **`sg-backend` (Contenedores ECS Back):**
  * Inbound: TCP Personalizado (Puerto 3000) permitiendo tráfico SOLO desde el ID de `sg-frontend`.
  * Outbound: Todo el tráfico hacia `0.0.0.0/0`.

### 3. Permisos e IAM
* El entorno corre bajo una cuenta académica de AWS Academy (Learner Lab / `voclabs`).
* Existe una restricción para crear nuevos roles IAM (`iam:CreateRole` denegado).
* **Solución acordada:** Se utilizará el rol preexistente llamado `LabRole` como *Task Execution Role* y *Task Role* en las Task Definitions de ECS.

### 4. Clúster ECS
* Nombre: `cluster-ep3`
* Tipo: Solo AWS Fargate.
* (Creado vía CLI para saltar restricciones de *Service Linked Roles* de la consola educativa).

### 5. Balanceador de Carga (ALB) y Target Group
* **Target Group (`tg-frontend`):**
  * Tipo de destino: Direcciones IP (Requerido para Fargate).
  * Puerto: 80.
  * No hay IPs registradas manualmente (se registrarán automáticamente al levantar las tareas en ECS).
* **Application Load Balancer (`alb-ep3`):**
  * Esquema: Expuesto a internet (Internet-facing).
  * Subredes: Asignado a las subredes públicas de la VPC.
  * Security Group: `sg-alb`.
  * Listener: Puerto 80 (HTTP) redirigiendo el tráfico hacia `tg-frontend`.

### 6. Repositorios de Imágenes (Amazon ECR)
Se crearon dos repositorios privados para almacenar las imágenes de Docker:
* `ep3-frontend`
* `ep3-backend`

---

## Próximos Pasos (Lo que necesito que me ayudes a hacer)
1. Escribir el código base / estructura para el Frontend y el Backend.
2. Crear un `Dockerfile` para el Frontend (debe exponer el puerto **80**).
3. Crear un `Dockerfile` para el Backend (debe exponer el puerto **3000**).
4. Preparar comandos para hacer el *build* de las imágenes y el *push* hacia los repositorios de ECR.
5. Preparar la estructura para un pipeline CI/CD con GitHub Actions (`.github/workflows/deploy.yml`) que automatice el despliegue hacia ECS Fargate.