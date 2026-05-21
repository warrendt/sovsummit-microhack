<#
.SYNOPSIS
    Create the "Microhack Sovereignty Summit" parent security group and
    nest the lab + admin groups inside it (idempotent).

.DESCRIPTION
    The Microhack prep guide (page 5) calls for a Security Group that holds
    every lab account so the coach can exclude it from the
    "Security info registration for Microsoft partners and vendors"
    Conditional Access policy in one step.

    This helper creates that parent group and nests the two operational
    groups (LabUsers + AdminUsers) inside it as group members. It is safe
    to re-run.

.PARAMETER GroupName
    Display name + mail nickname seed for the parent group.
    Default: "Microhack Sovereignty Summit".

.PARAMETER LabUsersGroup
    Name of the existing lab users group to nest. Default: "LabUsers".

.PARAMETER AdminGroup
    Name of the existing admin users group to nest. Default: "AdminUsers".

.PARAMETER SkipModuleInstall
    Skip the Install-PSResource bootstrap for Microsoft.Graph.Groups.

.EXAMPLE
    .\New-SummitSecurityGroup.ps1
.EXAMPLE
    .\New-SummitSecurityGroup.ps1 -GroupName "Microhack Sovereignty Summit ZA"
#>

[CmdletBinding()]
param(
    [string]$GroupName     = "Microhack Sovereignty Summit",
    [string]$LabUsersGroup = "LabUsers",
    [string]$AdminGroup    = "AdminUsers",
    [switch]$SkipModuleInstall
)

$ErrorActionPreference = "Stop"

if (-not $SkipModuleInstall) {
    foreach ($m in @('Microsoft.Graph.Groups')) {
        if (-not (Get-Module -ListAvailable -Name $m)) {
            Write-Host "Installing $m ..." -ForegroundColor DarkGray
            Install-PSResource -Name $m -TrustRepository -Scope CurrentUser -Quiet
        }
    }
}
Import-Module Microsoft.Graph.Groups -ErrorAction Stop

if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "Group.ReadWrite.All","Directory.Read.All" -UseDeviceCode
}

# -- Resolve or create the parent group ------------------------------------
$parent = Get-MgGroup -Filter "displayName eq '$GroupName'" -ConsistencyLevel eventual -CountVariable c | Select-Object -First 1
if (-not $parent) {
    $nick = ($GroupName -replace '[^a-zA-Z0-9]', '').ToLower()
    if (-not $nick) { $nick = "microhacksovsummit" }
    Write-Host "Creating parent security group: $GroupName ($nick)" -ForegroundColor Cyan
    $parent = New-MgGroup -DisplayName $GroupName `
                          -MailEnabled:$false `
                          -MailNickname $nick `
                          -SecurityEnabled:$true `
                          -Description "Microhack Sovereignty Summit — all lab + admin accounts. Excluded from the 'Security info registration for Microsoft partners and vendors' Conditional Access policy."
} else {
    Write-Host "Parent group already exists: $($parent.DisplayName) ($($parent.Id))" -ForegroundColor Green
}

# -- Nest the operational groups -------------------------------------------
foreach ($childName in @($LabUsersGroup, $AdminGroup)) {
    $child = Get-MgGroup -Filter "displayName eq '$childName'" -ConsistencyLevel eventual -CountVariable c | Select-Object -First 1
    if (-not $child) {
        Write-Warning "Child group '$childName' not found — skipping nesting. Create it first in Entra ID."
        continue
    }

    # Check if already a member
    $existing = Get-MgGroupMember -GroupId $parent.Id -All | Where-Object { $_.Id -eq $child.Id }
    if ($existing) {
        Write-Host ("  '{0}' is already nested inside '{1}'." -f $childName, $GroupName) -ForegroundColor Green
        continue
    }
    try {
        New-MgGroupMember -GroupId $parent.Id -DirectoryObjectId $child.Id | Out-Null
        Write-Host ("  Nested '{0}' inside '{1}'." -f $childName, $GroupName) -ForegroundColor Cyan
    } catch {
        if ($_.Exception.Message -match 'already exist|already a member|conflict|added object references already exist') {
            Write-Host ("  '{0}' already nested." -f $childName) -ForegroundColor Green
        } else {
            Write-Warning ("  Could not nest '{0}' inside '{1}': {2}" -f $childName, $GroupName, $_.Exception.Message)
        }
    }
}

Write-Host "" -ForegroundColor Green
Write-Host ("Parent security group : {0}" -f $parent.DisplayName) -ForegroundColor Green
Write-Host ("Object Id             : {0}" -f $parent.Id) -ForegroundColor Green
Write-Host "Use this object id with Set-CAExclusion.ps1 to exclude it from the 'Security info registration for Microsoft partners and vendors' CA policy." -ForegroundColor Gray
