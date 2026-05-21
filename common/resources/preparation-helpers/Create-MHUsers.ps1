#requires -Version 7
[CmdletBinding()]
param(
    [int]    $UserCount       = 65,
    [datetime]$EventStartDate = (Get-Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0 -Day 25 -Month 11 -Year 2025),
    [int]    $StartIndex      = 0,
    [string] $GroupName       = "LabUsers",
    [string] $UserNamePrefix  = "LabUser-",
    [string] $ExportPath      = ".\TemporaryAccessPasses.xlsx",
    [switch] $NonInteractive,
    [switch] $SkipModuleInstall
)

$RequiredModules = @(
    'Microsoft.Graph.Users',
    'Microsoft.Graph.Groups',
    'Microsoft.Graph.Identity.SignIns',
    'ImportExcel'
)

if (-not $SkipModuleInstall) {
    foreach ($module in $RequiredModules) {
        Install-PSResource -Name $module -TrustRepository
    }
}

# Remember to elevate via Privilege Identity Management (PIM) if needed before connecting, at least User Administrator and Group Administrator roles is required
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "User.ReadWrite.All","Group.ReadWrite.All","UserAuthenticationMethod.ReadWrite.All" -UseDeviceCode
}

Get-MgContext

# Lab users and group creation
$Password = New-Guid | Select-Object -ExpandProperty Guid # Generate a random password, this will not be used since TAP is configured
$UPNSuffix = '@' + ((Get-MgContext).Account -split "@")[1] # Get UPN suffix from the signed-in account (@xxx.onmicrosoft.com)
$eventStartDate = $EventStartDate
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
    $PasswordProfile.Password = $Password

    $UserParams = @{
        AccountEnabled = $true
        DisplayName = $UserName
        MailNickname = $UserName
        UserPrincipalName = $UserPrincipalName
        PasswordProfile = $PasswordProfile
        OutVariable = "CreatedUser"
    }

    Write-Host "Creating user : $UserPrincipalName"

    try {
        New-MgUser @UserParams
    }
    catch {
        Write-Host "Error creating user $UserPrincipalName : $_"
    }

    # Add user to group
    $UserId = $CreatedUser.Id
    try {
        New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $UserId
    }
    catch {
        Write-Host "Error adding user $UserPrincipalName to group $GroupName : $_"
    }

}

# Configure Temporary Access Pass (TAP) for users
# Note: TAP requires Entra ID Premium P2 license
# https://learn.microsoft.com/en-us/entra/identity/authentication/howto-authentication-temporary-access-pass
$UserNamePrefix = "LabUser-"
$Users = Get-MgUser -Filter "startsWith(DisplayName,'$UserNamePrefix')" | Sort-Object DisplayName | Where-Object UserPrincipalName -like "*$UPNSuffix"

$TAPs = @()

foreach ($user in $Users) {
    $properties = @{}
    $properties.isUsableOnce = $false
    $properties.startDateTime = $eventStartDate
    #$properties.startDateTime = (Get-Date).AddMinutes(1) # For testing purposes, set start time to 1 minute in the future
    $properties.endDateTime = $properties.startDateTime.AddDays(1)
    $propertiesJSON = $properties | ConvertTo-Json

    Write-Host "Creating Temporary Access Pass for user: $($user.UserPrincipalName)" -ForegroundColor Green

    try {
        New-MgUserAuthenticationTemporaryAccessPassMethod -UserId $user.Id -BodyParameter $propertiesJSON -OutVariable "CreatedTAP"
    }
    catch {
        Write-Host "Error creating TAP for user $($user.UserPrincipalName) : $_"
    }

$TAPs += [pscustomobject]@{
        UserPrincipalName = $user.UserPrincipalName
        TemporaryAccessPass = $CreatedTAP.TemporaryAccessPass
        LifetimeInMinutes = $CreatedTAP.LifetimeInMinutes
        IsUsableOnce = $CreatedTAP.IsUsableOnce
        StartDateTime = $CreatedTAP.StartDateTime
        EndDateTime = $CreatedTAP.StartDateTime.AddMinutes($CreatedTAP.LifetimeInMinutes)
    }

}

$exportArgs = @{
    InputObject   = $TAPs
    Path          = $ExportPath
    AutoSize      = $true
    Title         = "Temporary Access Passes"
    WorksheetName = "TAPs"
    TableName     = "TAPs"
    TableStyle    = "Light1"
}
if (-not $NonInteractive) { $exportArgs.Show = $true }
Export-Excel @exportArgs

Write-Host "Temporary Access Passes exported to $ExportPath" -ForegroundColor Green
Write-Host "Tip: Use the Mail merge feature in Word to create personalized instruction pages for users." -ForegroundColor Yellow