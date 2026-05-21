#requires -Version 7
<#
.SYNOPSIS
    Re-issue Temporary Access Passes for already-created lab users.

.DESCRIPTION
    Use this when Create-MHUsers.ps1 successfully created the users + group
    but TAP creation failed with "[accessDenied] : Request Authorization
    failed" — typically because Graph was previously connected with a token
    derived from Az PowerShell (which does NOT carry
    UserAuthenticationMethod.ReadWrite.All).

    This script forces a fresh Connect-MgGraph with the right delegated
    scopes (one device-code prompt) and re-issues a fresh 24-hour TAP for
    every user in the LabUsers group, then exports them to .xlsx.

.PARAMETER GroupName
    Entra ID group whose members should get new TAPs. Default: LabUsers.

.PARAMETER ExportPath
    Output .xlsx file (UPN | DisplayName | TAP | ResourceGroup).

.PARAMETER LifetimeMinutes
    TAP lifetime in minutes. Default 1440 (24 h). Max 43200 (30 d).

.EXAMPLE
    pwsh ./Retry-TAPs.ps1
    pwsh ./Retry-TAPs.ps1 -GroupName LabUsers -ExportPath ./TAPs.xlsx
#>
[CmdletBinding()]
param(
    [string]$GroupName       = 'LabUsers',
    [string]$ExportPath      = './TemporaryAccessPasses.xlsx',
    [int]   $LifetimeMinutes = 1440,
    [datetime]$StartDateTime,
    [string]$ResourceGroupPrefix = 'labuser-'
)

$ErrorActionPreference = 'Stop'

$requiredScopes = @(
    'User.Read.All',
    'Group.Read.All',
    'UserAuthenticationMethod.ReadWrite.All'
)

# Force a fresh Graph context with the right scopes
$ctx = Get-MgContext
$missing = @()
if ($ctx) { $missing = $requiredScopes | Where-Object { $_ -notin $ctx.Scopes } }
if (-not $ctx -or $missing.Count -gt 0) {
    if ($ctx) {
        Write-Host "Existing Graph context missing: $($missing -join ', '). Reconnecting..." -ForegroundColor Yellow
        try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch {}
    }
    Connect-MgGraph -Scopes $requiredScopes -UseDeviceCode
}

Write-Host "Graph context : $((Get-MgContext).Account)" -ForegroundColor Green
Write-Host "Graph scopes  : $((Get-MgContext).Scopes -join ', ')" -ForegroundColor Green

$group = Get-MgGroup -Filter "DisplayName eq '$GroupName'"
if (-not $group) { throw "Group '$GroupName' not found." }

$members = Get-MgGroupMember -GroupId $group.Id -All |
    ForEach-Object { Get-MgUser -UserId $_.Id -Property UserPrincipalName,DisplayName,Id }

if (-not $members) { throw "Group '$GroupName' has no members." }

Write-Host ("Found {0} member(s) of '{1}'. Issuing TAPs..." -f $members.Count, $GroupName) -ForegroundColor Cyan

$rows = @()
$failed = 0
foreach ($u in $members | Sort-Object UserPrincipalName) {
    $tapBody = @{
        lifetimeInMinutes = $LifetimeMinutes
        isUsableOnce      = $false
    }
    if ($StartDateTime) { $tapBody.startDateTime = $StartDateTime.ToString('o') }
    try {
        $tap = New-MgUserAuthenticationTemporaryAccessPassMethod `
            -UserId $u.Id `
            -BodyParameter $tapBody
        $rg = ($ResourceGroupPrefix + ($u.UserPrincipalName -split '@')[0].ToLower())
        $rows += [pscustomobject]@{
            UserPrincipalName = $u.UserPrincipalName
            DisplayName       = $u.DisplayName
            TAP               = $tap.TemporaryAccessPass
            ResourceGroup     = $rg
        }
        Write-Host ("  [OK]   {0}" -f $u.UserPrincipalName) -ForegroundColor DarkGreen
    } catch {
        $failed++
        Write-Host ("  [FAIL] {0}: {1}" -f $u.UserPrincipalName, $_.Exception.Message) -ForegroundColor Red
    }
}

if ($rows.Count -gt 0) {
    if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
        Install-PSResource -Name ImportExcel -TrustRepository | Out-Null
    }
    $rows | Export-Excel -Path $ExportPath -WorksheetName 'TAPs' -AutoSize -BoldTopRow
    Write-Host ""
    Write-Host ("Wrote {0} TAP(s) to {1}" -f $rows.Count, $ExportPath) -ForegroundColor Green
}
if ($failed -gt 0) {
    Write-Host ("{0} user(s) still failed. Check role assignments (Authentication Administrator) and Entra ID Premium P2 SKU." -f $failed) -ForegroundColor Yellow
}
