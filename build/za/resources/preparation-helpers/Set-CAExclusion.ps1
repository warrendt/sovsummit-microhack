<#
.SYNOPSIS
    Exclude a security group from the "Security info registration for
    Microsoft partners and vendors" Conditional Access policy (idempotent).

.DESCRIPTION
    Per Microhack prep guide pages 5-6, the lab users (and admins) need to
    register security info on their own devices, but the standard partner/
    vendor CA policy blocks them. The fix is to add the lab security group
    to the policy's excludeGroups collection.

    This helper attempts the change automatically via Microsoft Graph beta.
    If the caller's token lacks Policy.ReadWrite.ConditionalAccess (the
    az-CLI Graph token typically does), the helper prints clear copy-paste
    portal steps so the coach can finish in ~30 seconds.

.PARAMETER GroupName
    Display name of the security group to exclude.
    Default: "Microhack Sovereignty Summit".

.PARAMETER PolicyName
    Display name (or partial match) of the CA policy.
    Default: "Security info registration for Microsoft partners and vendors".

.PARAMETER SkipModuleInstall
    Skip the Install-PSResource bootstrap.

.EXAMPLE
    .\Set-CAExclusion.ps1
.EXAMPLE
    .\Set-CAExclusion.ps1 -GroupName "Microhack Sovereignty Summit" `
                          -PolicyName "Security info registration"
#>

[CmdletBinding()]
param(
    [string]$GroupName  = "Microhack Sovereignty Summit",
    [string]$PolicyName = "Security info registration for Microsoft partners and vendors",
    [switch]$SkipModuleInstall
)

$ErrorActionPreference = "Stop"

function Show-ManualSteps {
    param([string]$Group, [string]$Policy, [string]$Reason)
    Write-Host ""
    Write-Warning "Automatic CA exclusion was not applied: $Reason"
    Write-Host ""
    Write-Host "Apply manually in ~30 seconds:" -ForegroundColor Yellow
    Write-Host "  1. https://entra.microsoft.com  →  Protection  →  Conditional Access  →  Policies" -ForegroundColor Gray
    Write-Host "  2. Open the policy named:  $Policy" -ForegroundColor Gray
    Write-Host "  3. Users  →  Exclude  →  Users and groups  →  add:  $Group" -ForegroundColor Gray
    Write-Host "  4. Save." -ForegroundColor Gray
    Write-Host ""
    Write-Host "Reference (prep guide pages 5-6): aka.ms/SovereignCloudMicroHack" -ForegroundColor DarkGray
}

if (-not $SkipModuleInstall) {
    foreach ($m in @('Microsoft.Graph.Groups','Microsoft.Graph.Identity.SignIns')) {
        if (-not (Get-Module -ListAvailable -Name $m)) {
            Write-Host "Installing $m ..." -ForegroundColor DarkGray
            Install-PSResource -Name $m -TrustRepository -Scope CurrentUser -Quiet
        }
    }
}
Import-Module Microsoft.Graph.Groups, Microsoft.Graph.Identity.SignIns -ErrorAction Stop

if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "Group.Read.All","Policy.Read.All","Policy.ReadWrite.ConditionalAccess" -UseDeviceCode
}

# Resolve the security group
$group = Get-MgGroup -Filter "displayName eq '$GroupName'" -ConsistencyLevel eventual -CountVariable c | Select-Object -First 1
if (-not $group) {
    Show-ManualSteps -Group $GroupName -Policy $PolicyName -Reason "security group '$GroupName' not found (run New-SummitSecurityGroup.ps1 first)."
    return
}

# Find the CA policy. The Graph beta endpoint exposes conditionalAccess policies.
# Use exact-match first, fall back to startsWith.
$policy = $null
try {
    $policy = Get-MgIdentityConditionalAccessPolicy -All -ErrorAction Stop |
              Where-Object { $_.DisplayName -eq $PolicyName } |
              Select-Object -First 1
    if (-not $policy) {
        $policy = Get-MgIdentityConditionalAccessPolicy -All |
                  Where-Object { $_.DisplayName -like "$PolicyName*" -or $_.DisplayName -like "*$PolicyName*" } |
                  Select-Object -First 1
    }
} catch {
    Show-ManualSteps -Group $GroupName -Policy $PolicyName -Reason "could not enumerate CA policies — token likely lacks Policy.Read.All. ($($_.Exception.Message))"
    return
}

if (-not $policy) {
    Show-ManualSteps -Group $GroupName -Policy $PolicyName -Reason "no CA policy matches '$PolicyName' in this tenant."
    return
}

Write-Host ("Found CA policy: {0} ({1})" -f $policy.DisplayName, $policy.Id) -ForegroundColor Cyan

$existing = @()
if ($policy.Conditions -and $policy.Conditions.Users -and $policy.Conditions.Users.ExcludeGroups) {
    $existing = @($policy.Conditions.Users.ExcludeGroups)
}

if ($existing -contains $group.Id) {
    Write-Host ("Group '{0}' is already excluded from policy '{1}'." -f $GroupName, $policy.DisplayName) -ForegroundColor Green
    return
}

$newExcludes = @($existing + $group.Id) | Select-Object -Unique
$body = @{
    conditions = @{
        users = @{
            excludeGroups = $newExcludes
        }
    }
}

try {
    Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policy.Id -BodyParameter $body | Out-Null
    Write-Host ("Excluded '{0}' from CA policy '{1}'." -f $GroupName, $policy.DisplayName) -ForegroundColor Green
} catch {
    Show-ManualSteps -Group $GroupName -Policy $policy.DisplayName -Reason "PATCH failed (likely Policy.ReadWrite.ConditionalAccess scope missing). ($($_.Exception.Message))"
}
