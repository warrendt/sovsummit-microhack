<#
.SYNOPSIS
    Create resource groups and assign Owner role to MicroHack participants.

.DESCRIPTION
    This script is intended for MicroHack coaches who are preparing Azure subscriptions
    for lab participants. It automates the creation of resource groups and RBAC role
    assignments for each lab user.

    The script creates numbered resource groups (e.g., labuser-01, labuser-02, etc.)
    and assigns the Owner role to the corresponding user for their resource group.

    This setup ensures each lab participant has their own isolated resource group
    with full control to complete MicroHack exercises.

.PARAMETER SubscriptionName
    The name of the Azure subscription where resource groups should be created.
    Default: "Micro-Hack-1"

.PARAMETER Location
    The Azure region where resource groups should be created.
    Default: "northeurope"

.PARAMETER ResourceGroupPrefix
    The prefix for resource group names.
    Default: "labuser-"

.PARAMETER ResourceGroupCount
    The number of resource groups to create. Should match the number of users
    created in Create MH Users.ps1.
    Default: 60

.PARAMETER StartIndex
    The starting index for resource group numbering.
    Default: 0

.EXAMPLE
    .\4-resource-groups.ps1
    Creates resource groups using default values

.NOTES
    Author: MicroHack Team
    Date: February 2026

    Prerequisites:
    - Az.Accounts module
    - Az.Resources module
    - Appropriate permissions to create resource groups and assign RBAC roles
    - Users must be created first (see Create MH Users.ps1)

.LINK
    https://learn.microsoft.com/azure/azure-resource-manager/management/manage-resource-groups-powershell
.LINK
    https://learn.microsoft.com/azure/role-based-access-control/role-assignments-powershell
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionName = "Micro-Hack-1",

    [Parameter(Mandatory = $false)]
    [string]$Location = "northeurope",

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupPrefix = "labuser-",

    [Parameter(Mandatory = $false)]
    [int]$ResourceGroupCount = 60,

    [Parameter(Mandatory = $false)]
    [int]$StartIndex = 0
)

# Ensure required modules are available
$requiredModules = @('Az.Accounts', 'Az.Resources')
foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Error "$module module is not installed. Please run: Install-Module -Name $module"
        exit 1
    }
}

# Import required modules
Import-Module Az.Accounts, Az.Resources -ErrorAction Stop

Write-Host "`n=== Resource Group Creation Utility ===" -ForegroundColor Cyan
Write-Host "This script will create resource groups and assign Owner role to lab users."
Write-Host ""

# Check if user is logged in to Azure
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "No Azure context found. Please login..." -ForegroundColor Yellow
        Connect-AzAccount -UseDeviceAuthentication
        $context = Get-AzContext
    } else {
        Write-Host "Using Azure account: $($context.Account.Id)" -ForegroundColor Green
    }
} catch {
    Write-Error "Failed to get Azure context. Please run Connect-AzAccount first."
    exit 1
}

# Set subscription context
try {
    Set-AzContext -Subscription $SubscriptionName | Out-Null
    Write-Host "Using subscription: $SubscriptionName" -ForegroundColor Green
} catch {
    Write-Error "Failed to set subscription context: $($_.Exception.Message)"
    exit 1
}

$UPNSuffix = '@' + ((Get-AzContext).Account.Id -split "@")[1] # Get UPN suffix from the signed-in account (@xxx.onmicrosoft.com)

Write-Host "`nStarting resource group creation..." -ForegroundColor Cyan
Write-Host "  Prefix: $ResourceGroupPrefix" -ForegroundColor Gray
Write-Host "  Count: $ResourceGroupCount" -ForegroundColor Gray
Write-Host "  Location: $Location" -ForegroundColor Gray
Write-Host ""

for ($i = 1; $i -le $ResourceGroupCount; $i++) {

    $ResourceGroupNumber = $StartIndex+$i
    $ResourceGroupName = "$ResourceGroupPrefix$ResourceGroupNumber"
    $ResourceGroupName = "$ResourceGroupPrefix{0:D2}" -f $ResourceGroupNumber

    try {
        # -Force suppresses the [Y/N] confirm when the RG already exists.
        $null = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force
        Write-Host "Resource group $ResourceGroupName ready" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create resource group ${ResourceGroupName}: $($_.Exception.Message)" -ForegroundColor Red
        continue
    }

    Write-Host "Updating role assignments for resource group $ResourceGroupName" -ForegroundColor Cyan

     # Assign Owner role to the user for their respective resource group
     # Note: This requires the users to be created first, and may need to be adjusted based on how users are created and identified in your environment

    $SignInName = $ResourceGroupName + $UPNSuffix

    # Resolve the user object ID once so we can do idempotent role checks
    # (and bypass case-sensitive UPN matching issues with -SignInName).
    $userObjectId = $null
    try {
        $userObjectId = (Get-AzADUser -UserPrincipalName $SignInName -ErrorAction Stop).Id
    } catch {
        Write-Host "  [WARN] User '$SignInName' not found in directory — skipping role assignment. Create users first (Create-MHUsers.ps1)." -ForegroundColor Yellow
        continue
    }
    if (-not $userObjectId) {
        Write-Host "  [WARN] User '$SignInName' resolved but has no object id — skipping." -ForegroundColor Yellow
        continue
    }

    $rolesToAssign = @('Owner','Key Vault Administrator','Storage Account Contributor')
    $rgScope = "/subscriptions/$($context.Subscription.Id)/resourceGroups/$ResourceGroupName"

    foreach ($role in $rolesToAssign) {
        try {
            $existing = Get-AzRoleAssignment -ObjectId $userObjectId `
                                             -RoleDefinitionName $role `
                                             -Scope $rgScope `
                                             -ErrorAction SilentlyContinue
            if ($existing) {
                Write-Host "  [SKIP] '$role' already assigned to $SignInName" -ForegroundColor DarkGray
                continue
            }

            $null = New-AzRoleAssignment -ObjectId $userObjectId `
                                         -RoleDefinitionName $role `
                                         -Scope $rgScope `
                                         -ErrorAction Stop
            Write-Host "  [OK]   '$role' assigned to $SignInName" -ForegroundColor Green
        }
        catch {
            $msg = $_.Exception.Message
            if ($msg -match 'already exists|RoleAssignmentExists') {
                Write-Host "  [SKIP] '$role' already assigned to $SignInName" -ForegroundColor DarkGray
            } elseif ($msg -match 'AuthorizationFailed|does not have authorization|Forbidden') {
                Write-Host "  [DENY] cannot assign '$role' — caller lacks 'User Access Administrator' or 'Owner' at the RG/subscription scope. Run the Entra 'Elevate access' tenant-root toggle, or assign User Access Administrator first. Error: $msg" -ForegroundColor Red
            } else {
                Write-Host "  [FAIL] '$role' to ${SignInName}: $msg" -ForegroundColor Red
            }
        }
    }

}

Write-Host "`nResource group creation and role assignment process completed." -ForegroundColor Cyan