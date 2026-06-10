param(
  [Parameter(Mandatory = $true)][string]$OciRegion,
  [Parameter(Mandatory = $true)][string]$OciCompartmentId,
  [Parameter(Mandatory = $true)][string]$BackendImage,
  [Parameter(Mandatory = $true)][string]$FrontendImage,
  [string]$ModelId = "meta.llama-4-maverick-17b-128e-instruct-fp8",
  [string]$TemplatePath = "APP-DEMO/k8s/aplicaciones-demo.template.yaml",
  [string]$OutputPath = "APP-DEMO/k8s/aplicaciones-demo.rendered.yaml"
)

$ErrorActionPreference = "Stop"
$template = Get-Content -Raw -LiteralPath $TemplatePath
$content = $template.Replace("__OCI_REGION__", $OciRegion).
  Replace("__OCI_COMPARTMENT_ID__", $OciCompartmentId).
  Replace("__OCI_GENAI_MODEL_ID__", $ModelId).
  Replace("__BACKEND_IMAGE__", $BackendImage).
  Replace("__FRONTEND_IMAGE__", $FrontendImage)

$encoding = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText((Resolve-Path -LiteralPath (Split-Path -Parent $OutputPath)).Path + [System.IO.Path]::DirectorySeparatorChar + (Split-Path -Leaf $OutputPath), $content, $encoding)
Write-Host "Rendered $OutputPath"