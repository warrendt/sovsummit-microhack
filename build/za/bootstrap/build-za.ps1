<#
.SYNOPSIS
    One-shot bootstrap for the Sovereignty Summit South Africa 2026 workshop.

.DESCRIPTION
    Two modes:
      * Default (engineer) — stand up the sovereign foundation for a single
        engineer's subscription (you become Key Vault Admin).
      * -Coach            — ALSO run the multi-attendee prep scripts before
        the Bicep deployment: quota check, custom 'Deployment Validator' RBAC
        role for the LabUsers group, and N per-attendee resource groups.

    Engineer mode steps:
      1. Verify az CLI + Bicep.
      2. Make sure you are signed in to the right subscription.
      3. Register the resource providers the hack relies on.
      4. Deploy main.bicep at subscription scope into the primary region.
      5. Print outputs.

    Coach mode adds, before step 4:
      * 2-vcpu-quotas.ps1    (region quota check / optional submit)
      * 3-rbac.ps1           (custom Deployment Validator role + group RBAC)
      * 4-resource-groups.ps1 (numbered attendee RGs + Owner)

.PARAMETER SubscriptionId
    Target subscription. Defaults to the currently selected one.

.PARAMETER NamePrefix
    2-6 char lowercase prefix used in resource names. Defaults to 'sovza'.

.PARAMETER Location
    Primary region. Defaults to southafricanorth.

.PARAMETER WhatIf
    Preview the deployment without applying changes.

.PARAMETER Coach
    Switch into coach mode and run the per-summit prep scripts before the
    Bicep deployment.

.PARAMETER LabUsersGroup
    Entra ID group name receiving the lab RBAC. Defaults to 'LabUsers'.

.PARAMETER Attendees
    Number of attendees / numbered resource groups to create. Defaults to 10.

.PARAMETER ResourceGroupPrefix
    Prefix for attendee resource groups. Defaults to 'labuser-'.

.PARAMETER SubmitQuotaRequests
    Also submit vCPU quota increase requests via the Azure Quota REST API
    when running the quota check.

.EXAMPLE
    ./build-za.ps1
    ./build-za.ps1 -SubscriptionId <guid> -NamePrefix sov2026
    ./build-za.ps1 -WhatIf
    ./build-za.ps1 -Coach -Attendees 30
    ./build-za.ps1 -Coach -LabUsersGroup LabUsers -Attendees 30 -SubmitQuotaRequests
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SubscriptionId,
    [ValidatePattern('^[a-z]{2,6}$')]
    [string]$NamePrefix = 'sovza',
    [string]$Location   = 'southafricanorth',

    [switch]$Coach,
    [string]$LabUsersGroup = 'LabUsers',
    [int]$Attendees = 10,
    [string]$ResourceGroupPrefix = 'labuser-',
    [switch]$SubmitQuotaRequests,

    # <<<INTERNAL_ONLY>>>
    [switch]$CreateUsers,
    [int]$LabUserCount = 0,
    [int]$AdminUserCount = 5,
    [string]$AdminGroup = 'AdminUsers',
    [securestring]$AdminPassword,
    [datetime]$EventStartDate,
    [string]$TapExportPath
    # <<<END_INTERNAL_ONLY>>>
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
Write-Host "==> Mode         : $((if ($Coach) { 'coach (multi-attendee)' } else { 'engineer (single subscription)' }))"
Write-Host "==> Subscription : $($ctx.name) ($($ctx.id))"
Write-Host "==> Region       : $Location"
Write-Host "==> Prefix       : $NamePrefix"
Write-Host "==> Admin OID    : $signedInOid"
if ($Coach) {
    Write-Host "==> Group        : $LabUsersGroup"
    Write-Host "==> Attendees    : $Attendees (RGs: $($ResourceGroupPrefix)01 .. $('{0}{1:D2}' -f $ResourceGroupPrefix,$Attendees))"
    Write-Host "==> Submit quota : $($SubmitQuotaRequests.IsPresent)"
}
Write-Host ""

if (-not $PSCmdlet.ShouldProcess("Sovereignty Summit za foundation", "deploy")) {
    Write-Host "What-if mode: skipping deployment." -ForegroundColor Yellow
    return
}

$confirm = Read-Host "Proceed? [y/N]"
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

$scriptDir  = Split-Path -Parent $PSCommandPath
$bundleRoot = Split-Path -Parent $scriptDir
$prepDir    = Join-Path $bundleRoot 'resources/subscription-preparations'
$helpersDir = Join-Path $bundleRoot 'resources/preparation-helpers'

if ($Coach) {
    if (-not (Test-Path $prepDir)) {
        throw "Expected coach prep scripts at $prepDir but did not find them. Run this from a rendered build/za/bootstrap/ folder."
    }

    # <<<INTERNAL_ONLY>>>
    if ($CreateUsers) {
        if (-not (Test-Path $helpersDir)) {
            throw "-CreateUsers requires preparation helpers at $helpersDir."
        }
        if (-not $AdminPassword) {
            $AdminPassword = Read-Host -Prompt "Enter password for admin lab users" -AsSecureString
        }

        $lu = if ($LabUserCount -gt 0) { $LabUserCount } else { $Attendees }
        if (-not $TapExportPath) { $TapExportPath = Join-Path $bundleRoot 'TemporaryAccessPasses.xlsx' }

        Write-Host ""
        Write-Host "==> [coach] Create-MHUsers.ps1 — creating $lu lab users in group '$LabUsersGroup' (tenant scope)..." -ForegroundColor Cyan
        $mhArgs = @{
            UserCount     = $lu
            GroupName     = $LabUsersGroup
            ExportPath    = $TapExportPath
            NonInteractive = $true
        }
        if ($EventStartDate) { $mhArgs.EventStartDate = $EventStartDate }
        & (Join-Path $helpersDir 'Create-MHUsers.ps1') @mhArgs

        Write-Host ""
        Write-Host "==> [coach] Create-AdminUsers.ps1 — creating $AdminUserCount admin users in group '$AdminGroup' (tenant scope)..." -ForegroundColor Cyan
        & (Join-Path $helpersDir 'Create-AdminUsers.ps1') -UserCount $AdminUserCount -GroupName $AdminGroup -Password $AdminPassword
    }
    # <<<END_INTERNAL_ONLY>>>

    Write-Host ""
    Write-Host "==> [coach] 2-vcpu-quotas.ps1 — checking vCPU quota in $Location for $Attendees attendees..." -ForegroundColor Cyan
    $quotaArgs = @('-Region', $Location, '-NumberOfLabUsers', $Attendees)
    if ($SubmitQuotaRequests) { $quotaArgs += '-SubmitQuotaRequests' }
    try { & (Join-Path $prepDir '2-vcpu-quotas.ps1') @quotaArgs }
    catch { Write-Warning "Quota check returned an error (often expected when a request is filed). Continuing." }

    Write-Host ""
    Write-Host "==> [coach] 3-rbac.ps1 — custom 'Deployment Validator' role + group RBAC for '$LabUsersGroup'..." -ForegroundColor Cyan
    & (Join-Path $prepDir '3-rbac.ps1') -GroupName $LabUsersGroup -SubscriptionId $ctx.id

    Write-Host ""
    Write-Host "==> [coach] 4-resource-groups.ps1 — creating $Attendees attendee resource groups in $Location..." -ForegroundColor Cyan
    & (Join-Path $prepDir '4-resource-groups.ps1') `
        -SubscriptionName $ctx.name `
        -Location $Location `
        -ResourceGroupPrefix $ResourceGroupPrefix `
        -ResourceGroupCount $Attendees `
        -StartIndex 0
}

$deployName = "$NamePrefix-bootstrap-$(Get-Date -Format yyyyMMdd-HHmmss)"

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
Write-Host " Sovereignty Summit South Africa 2026 foundation is up."
Write-Host " Next: open challenges/challenge-01.md and start enforcing the"
Write-Host " Sovereignty initiative."
Write-Host "========================================================================="
