param(
  [Parameter(Mandatory = $true)][string]$CompartmentId,
  [string]$RepositoryPrefix = "devops-oke"
)

$ErrorActionPreference = "Stop"
oci artifacts container repository create --display-name "$RepositoryPrefix/backend" --compartment-id $CompartmentId --is-public false
oci artifacts container repository create --display-name "$RepositoryPrefix/frontend" --compartment-id $CompartmentId --is-public false