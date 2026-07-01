param(
    [Parameter(Mandatory = $true)]
    [string]$AWS_ACCOUNT_ID,
    [Parameter(Mandatory = $true)]
    [string]$AWS_REGION,
    [Parameter(Mandatory = $true)]
    [string]$VPC_ID,
    [Parameter(Mandatory = $true)]
    [string]$SUBNET_PRIVATE_1,
    [Parameter(Mandatory = $true)]
    [string]$SUBNET_PRIVATE_2,
    [Parameter(Mandatory = $true)]
    [string]$SG_FRONTEND_ID,
    [Parameter(Mandatory = $true)]
    [string]$SG_BACKEND_ID,
    [Parameter(Mandatory = $true)]
    [string]$TG_FRONTEND_ARN
)

Write-Host "=== Desplegando ECS Services ==="

# Crear CloudWatch Logs groups
aws logs create-log-group --log-group-name /ecs/task-frontend --region $AWS_REGION
aws logs create-log-group --log-group-name /ecs/task-backend --region $AWS_REGION

# Reemplazar ACCOUNT_ID en task definitions
(Get-Content "..\aws\task-definition-frontend.json") -replace "ACCOUNT_ID", $AWS_ACCOUNT_ID | Set-Content "..\aws\task-definition-frontend-resolved.json"
(Get-Content "..\aws\task-definition-backend.json") -replace "ACCOUNT_ID", $AWS_ACCOUNT_ID | Set-Content "..\aws\task-definition-backend-resolved.json"

# Registrar task definitions
Write-Host "Registrando task definitions..."
aws ecs register-task-definition --cli-input-json file://..\aws\task-definition-frontend-resolved.json --region $AWS_REGION
aws ecs register-task-definition --cli-input-json file://..\aws\task-definition-backend-resolved.json --region $AWS_REGION

# Crear servicio Backend (sin ALB)
Write-Host "Creando servicio backend..."
aws ecs create-service `
    --cluster cluster-ep3 `
    --service-name service-backend `
    --task-definition task-backend `
    --desired-count 1 `
    --launch-type FARGATE `
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_PRIVATE_1,$SUBNET_PRIVATE_2],securityGroups=[$SG_BACKEND_ID],assignPublicIp=DISABLED}" `
    --region $AWS_REGION

# Crear servicio Frontend (con ALB)
Write-Host "Creando servicio frontend..."
aws ecs create-service `
    --cluster cluster-ep3 `
    --service-name service-frontend `
    --task-definition task-frontend `
    --desired-count 1 `
    --launch-type FARGATE `
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_PRIVATE_1,$SUBNET_PRIVATE_2],securityGroups=[$SG_FRONTEND_ID],assignPublicIp=DISABLED}" `
    --load-balancers "targetGroupArn=$TG_FRONTEND_ARN,containerName=frontend,containerPort=80" `
    --region $AWS_REGION

Write-Host "=== Despliegue completado ==="
