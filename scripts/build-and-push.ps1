param(
  [Parameter(Mandatory = $true)][string]$OcirRegionKey,
  [Parameter(Mandatory = $true)][string]$TenancyNamespace,
  [string]$RepositoryPrefix = "devops-oke",
  [string]$Tag = "1.0.0"
)

$ErrorActionPreference = "Stop"
$registry = "$OcirRegionKey.ocir.io"
$backendImage = "$registry/$TenancyNamespace/$RepositoryPrefix/backend:$Tag"
$frontendImage = "$registry/$TenancyNamespace/$RepositoryPrefix/frontend:$Tag"

Write-Host "Building backend: $backendImage"
docker build -f APP-DEMO/app/backend/Dockerfile.backend -t $backendImage APP-DEMO/app/backend

Write-Host "Building frontend: $frontendImage"
docker build -f APP-DEMO/app/frontend/Dockerfile.front -t $frontendImage APP-DEMO/app/frontend

Write-Host "Pushing backend"
docker push $backendImage

Write-Host "Pushing frontend"
docker push $frontendImage

Write-Host "BACKEND_IMAGE=$backendImage"
Write-Host "FRONTEND_IMAGE=$frontendImage"