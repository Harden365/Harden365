<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.DeviceHardenApp.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   06/15/2022
        Last Updated: 06/15/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Create Azure AD Application Harden365

    .DESCRIPTION

#>

Function Start-Harden365App {
     <#
        .Synopsis
         DeviceConfigImport
        
        .Description
         This function will 

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
)

Write-LogSection 'CREATE HARDEN365 APP' -NoHostOutput


#### HARDEN365 APP #####

#region Create Harden365 App
$DomainOnM365 = (Get-MgDomain | Where-Object { $_.IsDefault -eq $true }).Id
$appName = "Harden365 App"
$appURI = "https://harden365." +$DomainOnM365
$appHomePageUrl = "https://hardenad.net/"
$appReplyURLs = "https://hardenad.net"
Write-LogInfo "Create Harden365 App"
if(!($HardenApp = Get-MgApplication -Filter "DisplayName eq '$($appName)'"  -ErrorAction SilentlyContinue))
{ $HardenApp = New-MgApplication -DisplayName $appName -IdentifierUris $appURI -Web @{ RedirectUris = $appReplyURLs; } #-LogoInputFile $logo
  $logo = Join-Path (Get-Location) "\Config\Harden365App.jpg"
  $HardenAppId = $HardenApp.AppId
  #Set-AzureADApplicationLogo -ObjectId $HardenApp.ObjectId -FilePath $logo
  Write-LogInfo "Create Client secret"

  $passwordCred = @{
    "displayName" = "Harden365ClientSecret"
    "endDateTime" = (Get-Date).AddMonths(+12)
    }
  $ClientSecret = Add-MgApplicationPassword -ApplicationId $HardenApp.Id -PasswordCredential $passwordCred
  write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Please keep Harden365 App secret : ') -ForegroundColor yellow -NoNewline ; Write-host $($ClientSecret.SecretText) -ForegroundColor Red
}

#endregion

#Get Service Principal of Microsoft Graph Resource API
$Harden365App = Get-MgApplication -Filter "DisplayName eq '$($appName)'"
$graphSP =  Get-MgServicePrincipal -All | Where-Object {$_.DisplayName -eq "Microsoft Graph"}
 
#Set Application Permissions
$ApplicationPermissions = @(
'DeviceManagementApps.ReadWrite.All',
'DeviceManagementConfiguration.ReadWrite.All',
'DeviceManagementManagedDevices.PrivilegedOperations.All',
'DeviceManagementManagedDevices.ReadWrite.All',
'DeviceManagementRBAC.ReadWrite.All',
'DeviceManagementServiceConfig.ReadWrite.All',
'Directory.Read.All',
'Group.Read.All',
'Group.ReadWrite.All'
)
 
#Add app permissions
$ResourceAccessArray = @()
ForEach ($permission in $ApplicationPermissions) {
$reqPermission = $null
#Get required app permission
$reqPermission = $graphSP.AppRoles | Where-Object {$_.Value -eq $permission}
if($reqPermission)
{
$resourceAccess = @{
    Type = "Role"
    Id = $reqPermission.Id    }
$ResourceAccessArray += $resourceAccess
}
else
{
Write-LogWarning "App permission $permission not found in the Graph Resource API"
}
}

 
#Set permissions in existing Azure AD App
$appObjectId=$Harden365App.Id
Update-MgApplication -ApplicationId $appObjectId -RequiredResourceAccess @{ ResourceAppId=$graphSP.AppId; ResourceAccess=$ResourceAccessArray }

#region AdminConsent
## Get the TenantID
$tenantID = $(Get-MgContext).TenantId
## Browse this URL
$consentURL = "https://login.microsoftonline.com/$tenantID/adminconsent?client_id=$($HardenApp.AppId)"
## Launch the consent URL using the default browser
Write-LogInfo "Please wait for admin consent..."
Start-sleep -Seconds 20
Start-Process -FilePath "msedge.exe"  -ArgumentList "--inprivate $consentURL --start-fullscreen"
Write-LogInfo "Installation complete"
#endregion
}

