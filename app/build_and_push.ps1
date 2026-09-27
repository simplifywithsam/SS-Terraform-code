# Build the sample app image and push it to Artifactory (Windows / PowerShell).
# Usage:
#   $env:ARTIFACTORY_REGISTRY = "mycompany.jfrog.io"
#   $env:ARTIFACTORY_REPO     = "iec-docker-local"
#   $env:ARTIFACTORY_USER     = "svc-user"
#   $env:ARTIFACTORY_TOKEN    = "<token>"
#   .\build_and_push.ps1 -ImageTag 1.0.0
param(
    [string]$ImageName = "iec-sample-app",
    [string]$ImageTag  = ""
)
$ErrorActionPreference = "Stop"

foreach ($v in "ARTIFACTORY_REGISTRY","ARTIFACTORY_REPO","ARTIFACTORY_USER","ARTIFACTORY_TOKEN") {
    if (-not [Environment]::GetEnvironmentVariable($v)) { throw "Set environment variable $v" }
}

if (-not $ImageTag) {
    $ImageTag = (git rev-parse --short HEAD 2>$null)
    if (-not $ImageTag) { $ImageTag = Get-Date -Format "yyyyMMddHHmmss" }
}

$ImageRef = "$($env:ARTIFACTORY_REGISTRY)/$($env:ARTIFACTORY_REPO)/$($ImageName):$ImageTag"
Set-Location $PSScriptRoot

$buildArgs = @()
if ($env:BASE_IMAGE)    { $buildArgs += @("--build-arg", "BASE_IMAGE=$($env:BASE_IMAGE)") }
if ($env:PIP_INDEX_URL) { $buildArgs += @("--build-arg", "PIP_INDEX_URL=$($env:PIP_INDEX_URL)") }

Write-Host ">> Logging in to $($env:ARTIFACTORY_REGISTRY)"
$env:ARTIFACTORY_TOKEN | docker login $env:ARTIFACTORY_REGISTRY -u $env:ARTIFACTORY_USER --password-stdin
if ($LASTEXITCODE -ne 0) { throw "docker login failed" }

Write-Host ">> Building $ImageRef (linux/amd64 for Fargate X86_64)"
docker build --platform linux/amd64 @buildArgs -t $ImageRef .
if ($LASTEXITCODE -ne 0) { throw "docker build failed" }

Write-Host ">> Pushing $ImageRef"
docker push $ImageRef
if ($LASTEXITCODE -ne 0) { throw "docker push failed" }

Write-Host "`nPushed: $ImageRef"
Write-Host "Set in ecs-service/dev.tfvars:  container_image = `"$ImageRef`""
