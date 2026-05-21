<#
.SYNOPSIS
    One-shot bootstrap for the ${country.summit_edition} workshop.

.DESCRIPTION
    Registers required resource providers and deploys main.bicep at
    subscription scope into ${country.azure.primary_region}, producing the
    foundation resource group + Premium Key Vault (HSM-backed) + CMK key +
    storage account + Log Analytics workspace, plus the Allowed-Locations
    policy assignments that pin everything to ${country.name} regions.

.PARAMETER SubscriptionId
    Target subscription. Defaults to the currently selected one.

.PARAMETER NamePrefix
    2-6 char lowercase prefix used in resource names. Defaults to 'sovza'.

.PARAMETER Location
    Primary region. Defaults to ${country.azure.primary_region}.

.PARAMETER WhatIf
    Preview the deployment without applying changes.

.EXAMPLE
    ./build-za.ps1
    ./build-za.ps1 -SubscriptionId <guid> -NamePrefix sov2026
    ./build-za.ps1 -WhatIf
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SubscriptionId,
    [ValidatePattern('^[a-z]{2,6}$')]
    [string]$NamePrefix = 'sovza',
    [string]$Location   = '${country.azure.primary_region}'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "az CLI not found. Install from https://learn.microsoft.com/cli/azure/install-azure-cli"
}
az bicep version *> $null
if ($LASTEXITCODE -ne 0) { az bicep install | Out-Null }

az account show *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Not logged in. Running 'az login --use-device-code'..." -ForegroundColor Yellow
    az login --use-device-code | Out-Null
}

if ($SubscriptionId) {
    az account set --subscription $SubscriptionId | Out-Null
}

$ctx = az account show -o json | ConvertFrom-Json
$signedInOid = az ad signed-in-user show --query id -o tsv

Write-Host ""
Write-Host "==> Subscription : $($ctx.name) ($($ctx.id))"
Write-Host "==> Region       : $Location"
Write-Host "==> Prefix       : $NamePrefix"
Write-Host "==> Admin OID    : $signedInOid"
Write-Host ""

if (-not $PSCmdlet.ShouldProcess("Sovereignty Summit ${country.iso2} foundation", "deploy")) {
    Write-Host "What-if mode: skipping deployment." -ForegroundColor Yellow
    return
}

$confirm = Read-Host "Proceed with the deployment? [y/N]"
if ($confirm -notmatch '^(y|Y)') { Write-Host "Aborted."; return }

Write-Host ""
Write-Host "==> Registering resource providers (idempotent)..." -ForegroundColor Cyan
$providers = @(
  'Microsoft.HybridCompute','Microsoft.GuestConfiguration','Microsoft.HybridConnectivity',
  'Microsoft.AzureArcData','Microsoft.AzureStackHCI','Microsoft.ResourceConnector',
  'Microsoft.HybridContainerService','Microsoft.Compute','Microsoft.ConfidentialLedger',
  'Microsoft.Security','Microsoft.PolicyInsights','Microsoft.Advisor',
  'Microsoft.OperationsManagement','Microsoft.OperationalInsights','Microsoft.Insights',
  'Microsoft.Monitor','Microsoft.KeyVault','Microsoft.ManagedIdentity','Microsoft.Network',
  'Microsoft.Storage','Microsoft.Attestation','Microsoft.Kubernetes',
  'Microsoft.KubernetesConfiguration','Microsoft.ContainerService','Microsoft.ExtendedLocation'
)
$jobs = $providers | ForEach-Object {
  Start-Job -ScriptBlock { param($n) az provider register --namespace $n --wait | Out-Null } -ArgumentList $_
}
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job
Write-Host "    providers registered."

$deployName = "$NamePrefix-bootstrap-$(Get-Date -Format yyyyMMdd-HHmmss)"
$scriptDir  = Split-Path -Parent $PSCommandPath

Write-Host ""
Write-Host "==> Deploying main.bicep at subscription scope..." -ForegroundColor Cyan
az deployment sub create `
  --name $deployName `
  --location $Location `
  --template-file (Join-Path $scriptDir 'main.bicep') `
  --parameters (Join-Path $scriptDir 'main.bicepparam') `
  --parameters adminObjectId=$signedInOid namePrefix=$NamePrefix | Out-Null

Write-Host ""
Write-Host "==> Deployment outputs" -ForegroundColor Cyan
az deployment sub show -n $deployName --query 'properties.outputs' -o json

Write-Host ""
Write-Host "========================================================================="
Write-Host " ${country.summit_edition} foundation is up."
Write-Host " Next: open challenges/challenge-01.md and start enforcing the"
Write-Host " Sovereignty initiative."
Write-Host "========================================================================="
