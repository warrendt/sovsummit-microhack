#requires -Version 7
<#
.SYNOPSIS
    Repair partial Create-MHUsers run — adds existing LabUser-NN users to
    the LabUsers group AND issues a fresh TAP for each one.

.DESCRIPTION
    Use this after Create-MHUsers.ps1 created the user objects but the
    "Add to group" and TAP-create steps failed with 'Insufficient
    privileges' / '[accessDenied]'. Typical cause: the signed-in admin
    had the OAuth scopes (User/Group/UserAuthenticationMethod) but their
    PIM-eligible role (Global Administrator OR Groups Administrator +
    Authentication Administrator) was not active at the time of the run.

    BEFORE running this script:
      1. Activate the role in Entra → PIM → My roles → Eligible.
      2. Wait 1-2 minutes for role propagation.
      3. Sign out / sign back in via Connect-MgGraph so the token picks
         up the freshly-activated role. (This script forces a fresh
         Disconnect+Connect with -UseDeviceCode for that reason.)

.PARAMETER UserPrefix
    User principal prefix. Default: 'LabUser-'.

.PARAMETER UserCount
    How many sequentially-numbered users to repair. Default: 40.

.PARAMETER GroupName
    Target group. Default: 'LabUsers'.

.PARAMETER ExportPath
    Output xlsx. Default: ./TemporaryAccessPasses.xlsx (relative to caller).
#>
[CmdletBinding()]
param(
    [string]$UserPrefix     = 'LabUser-',
    [int]   $UserCount      = 40,
    [string]$GroupName      = 'LabUsers',
    [string]$ExportPath     = './TemporaryAccessPasses.xlsx',
    [int]   $LifetimeMinutes = 1440,
    [string]$ResourceGroupPrefix = 'labuser-'
)

$ErrorActionPreference = 'Stop'

$requiredScopes = @(
    'User.Read.All',
    'Group.ReadWrite.All',
    'UserAuthenticationMethod.ReadWrite.All'
)

# Force a fresh sign-in so newly-activated PIM roles end up in the token.
try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch {}
Connect-MgGraph -Scopes $requiredScopes -UseDeviceCode

$ctx = Get-MgContext
Write-Host ""
Write-Host "Graph context : $($ctx.Account)" -ForegroundColor Green
Write-Host "Graph scopes  : $($ctx.Scopes -join ', ')" -ForegroundColor Green
Write-Host ""

# Locate / create LabUsers group
$group = Get-MgGroup -Filter "DisplayName eq '$GroupName'"
if (-not $group) {
    Write-Host "Group '$GroupName' missing — creating..." -ForegroundColor Yellow
    $group = New-MgGroup -DisplayName $GroupName -MailEnabled:$false `
                        -MailNickname $GroupName -SecurityEnabled:$true
}
$groupId = $group.Id

# Snapshot current members
$currentMembers = Get-MgGroupMember -GroupId $groupId -All |
    ForEach-Object { $_.Id }

$upnSuffix = '@' + (($ctx.Account) -split '@')[1]
$rows = @()
$added = 0
$alreadyIn = 0
$tapOk = 0
$tapFail = 0
$notFound = 0

for ($i = 1; $i -le $UserCount; $i++) {
    $userName = "{0}{1:D2}" -f $UserPrefix, $i
    $upn      = $userName + $upnSuffix
    $rg       = $ResourceGroupPrefix + $userName.ToLower()

    $user = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
    if (-not $user) {
        Write-Host "  [MISSING] $upn — skip" -ForegroundColor Yellow
        $notFound++
        continue
    }

    # Group membership
    if ($currentMembers -contains $user.Id) {
        $alreadyIn++
    } else {
        try {
            New-MgGroupMember -GroupId $groupId -DirectoryObjectId $user.Id -ErrorAction Stop | Out-Null
            $added++
        } catch {
            if ($_.Exception.Message -match 'already exist') {
                $alreadyIn++
            } else {
                Write-Host ("  [GROUP-FAIL] {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Red
            }
        }
    }

    # TAP
    try {
        $tap = New-MgUserAuthenticationTemporaryAccessPassMethod `
                -UserId $user.Id `
                -BodyParameter @{
                    lifetimeInMinutes = $LifetimeMinutes
                    isUsableOnce      = $false
                }
        $rows += [pscustomobject]@{
            UserPrincipalName = $upn
            DisplayName       = $user.DisplayName
            TAP               = $tap.TemporaryAccessPass
            ResourceGroup     = $rg
        }
        $tapOk++
        Write-Host ("  [OK]   {0}" -f $upn) -ForegroundColor DarkGreen
    } catch {
        $tapFail++
        Write-Host ("  [TAP-FAIL] {0}: {1}" -f $upn, $_.Exception.Message) -ForegroundColor Red
    }
}

if ($rows.Count -gt 0) {
    if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
        Install-PSResource -Name ImportExcel -TrustRepository | Out-Null
    }
    $rows | Export-Excel -Path $ExportPath -WorksheetName 'TAPs' -AutoSize -BoldTopRow
}

Write-Host ""
Write-Host "==== Summary ====" -ForegroundColor Cyan
Write-Host ("  Users found      : {0}/{1}" -f ($UserCount - $notFound), $UserCount)
Write-Host ("  Added to group   : $added")
Write-Host ("  Already in group : $alreadyIn")
Write-Host ("  TAPs issued      : $tapOk")
Write-Host ("  TAPs failed      : $tapFail")
if ($rows.Count -gt 0) {
    Write-Host ("  Export file      : $ExportPath") -ForegroundColor Green
}
if ($tapFail -gt 0) {
    Write-Host ""
    Write-Host "Some TAPs failed. Most common cause: the signed-in admin lacks the 'Authentication Administrator' or 'Global Administrator' directory role. Activate via PIM and re-run this script." -ForegroundColor Yellow
}
