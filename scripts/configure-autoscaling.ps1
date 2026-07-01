param(
    [Parameter(Mandatory = $true)]
    [string]$AWS_REGION
)

Write-Host "=== Configurando Autoscaling para ECS Services ==="

# Autoscaling para Frontend
Write-Host "Configurando autoscaling para service-frontend..."
aws application-autoscaling register-scalable-target `
    --service-namespace ecs `
    --resource-id "service/cluster-ep3/service-frontend" `
    --scalable-dimension "ecs:service:DesiredCount" `
    --min-capacity 1 `
    --max-capacity 3 `
    --region $AWS_REGION

aws application-autoscaling put-scaling-policy `
    --service-namespace ecs `
    --resource-id "service/cluster-ep3/service-frontend" `
    --scalable-dimension "ecs:service:DesiredCount" `
    --policy-name "cpu-target-frontend" `
    --policy-type TargetTrackingScaling `
    --target-tracking-scaling-policy-configuration file://../aws/scaling-policy-frontend.json `
    --region $AWS_REGION

# Autoscaling para Backend
Write-Host "Configurando autoscaling para service-backend..."
aws application-autoscaling register-scalable-target `
    --service-namespace ecs `
    --resource-id "service/cluster-ep3/service-backend" `
    --scalable-dimension "ecs:service:DesiredCount" `
    --min-capacity 1 `
    --max-capacity 3 `
    --region $AWS_REGION

aws application-autoscaling put-scaling-policy `
    --service-namespace ecs `
    --resource-id "service/cluster-ep3/service-backend" `
    --scalable-dimension "ecs:service:DesiredCount" `
    --policy-name "cpu-target-backend" `
    --policy-type TargetTrackingScaling `
    --target-tracking-scaling-policy-configuration file://../aws/scaling-policy-backend.json `
    --region $AWS_REGION

Write-Host "=== Autoscaling configurado ==="
Write-Host "Umbral: 50% de CPU - Min: 1 tarea - Max: 3 tareas"
