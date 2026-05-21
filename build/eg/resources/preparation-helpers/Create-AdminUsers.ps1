#requires -Version 7
[CmdletBinding()]
param(
    [int]    $UserCount      = 5,
    [int]    $StartIndex     = 0,
    [string] $GroupName      = "AdminUsers",
    [string] $UserNamePrefix = "AdminLabUser-",
    [securestring] $Password,
    [switch] $SkipModuleInstall
)

$RequiredModules = @(
    'Microsoft.Graph.Users',
    'Microsoft.Graph.Groups'
)

if (-not $SkipModuleInstall) {
    foreach ($module in $RequiredModules) {
        Install-PSResource -Name $module -TrustRepository
    }
}

$requiredScopes = @('User.ReadWrite.All','Group.ReadWrite.All','UserAuthenticationMethod.ReadWrite.All')
$ctx = Get-MgContext
$missingScopes = @()
if ($ctx) {
    $missingScopes = $requiredScopes | Where-Object { $_ -notin $ctx.Scopes }
}
if (-not $ctx -or $missingScopes.Count -gt 0) {
    if ($ctx -and $missingScopes.Count -gt 0) {
        Write-Host "Existing Graph context is missing scopes: $($missingScopes -join ', '). Reconnecting..." -ForegroundColor Yellow
        try { Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null } catch {}
    }
    Connect-MgGraph -Scopes $requiredScopes -UseDeviceCode
}

Get-MgContext

# Lab users and group creation
if (-not $Password) {
    $Password = Read-Host -Prompt "Enter password" -AsSecureString
}
$PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
$UPNSuffix = '@' + ((Get-MgContext).Account -split "@")[1] # Get UPN suffix from the signed-in account (@xxx.onmicrosoft.com)
$GroupId = Get-MgGroup -Filter "DisplayName eq '$GroupName'" | Select-Object -ExpandProperty Id
if (-not $GroupId) {
    $GroupParams = @{
        DisplayName     = $GroupName
        MailEnabled     = $false
        MailNickname    = $GroupName
        SecurityEnabled = $true
    }

    $Group = New-MgGroup @GroupParams
    $GroupId = $Group.Id
}

foreach ($i in 1..$UserCount) {

    $UserNumber = $StartIndex+$i
    $UserName = "$UserNamePrefix$UserNumber"
    $UserName = "$UserNamePrefix{0:D2}" -f $UserNumber
    $UserPrincipalName = $UserName + $UPNSuffix
    $PasswordProfile = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphPasswordProfile
    $PasswordProfile.ForceChangePasswordNextSignIn = $true
    $PasswordProfile.Password = $PlainPassword

    $UserParams = @{
        AccountEnabled = $true
        DisplayName = $UserName
        MailNickname = $UserName
        UserPrincipalName = $UserPrincipalName
        PasswordProfile = $PasswordProfile
        OutVariable = "CreatedUser"
    }

    Write-Host "Creating user : $UserPrincipalName"

    $existing = Get-MgUser -Filter "userPrincipalName eq '$UserPrincipalName'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "  exists, skipping create."
        $CreatedUser = @{ Id = $existing.Id }
    } else {
        try {
            New-MgUser @UserParams | Out-Null
        }
        catch {
            Write-Host "Error creating user $UserPrincipalName : $_"
        }
    }

    # Add user to group (idempotent)
    $UserId = $CreatedUser.Id
    if ($UserId -and $GroupId) {
        try {
            New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $UserId -ErrorAction Stop | Out-Null
        }
        catch {
            if ($_.Exception.Message -notmatch 'already exist|added object references already exist') {
                Write-Host "Error adding user $UserPrincipalName to group $GroupName : $_"
            }
        }
    }

}