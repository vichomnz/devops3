param(
    [Parameter(Mandatory = $true)]
    [string]$AWS_ACCOUNT_ID,
    [Parameter(Mandatory = $true)]
    [string]$AWS_REGION
)

$ECR_FRONTEND = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ep3-frontend"
$ECR_BACKEND = "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/ep3-backend"

Write-Host "=== Login a ECR ==="
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

Write-Host "=== Build Frontend ==="
docker build -t ep3-frontend:latest --build-arg VITE_API_URL=http://localhost:3000 "..\proyecto semestral\front_despacho"
docker tag ep3-frontend:latest "$ECR_FRONTEND`:latest"
docker push "$ECR_FRONTEND`:latest"

Write-Host "=== Build Backend ==="
docker build -t ep3-backend:latest "..\proyecto semestral\backend"
docker tag ep3-backend:latest "$ECR_BACKEND`:latest"
docker push "$ECR_BACKEND`:latest"

Write-Host "=== Build y push completados ==="
