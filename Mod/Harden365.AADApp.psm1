﻿#### HARDEN365 APP #####

#region Create Secret
$Secret = New-Guid
$startDate = Get-Date
$PasswordCredential = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordCredential
$PasswordCredential.StartDate = $startDate
$PasswordCredential.EndDate = $startDate.AddYears(1)
$PasswordCredential.KeyId = $Secret
$PasswordCredential.Value = ([System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($Secret))))
$SecretPass = $PasswordCredential.Value
#endregion

#region Create Harden365 App
$DomainOnM365 = (Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$appName = 'Harden365 App'
$appURI = 'https://harden365.' + $DomainOnM365
$appHomePageUrl = 'https://hardenad.net/'
$appReplyURLs = @($appURI, 'https://localhost:1234')
if (!($HardenApp = Get-AzureADApplication -Filter "DisplayName eq '$($appName)'" -ErrorAction SilentlyContinue)) {
  $HardenApp = New-AzureADApplication -DisplayName $appName -IdentifierUris $appURI -Homepage $appHomePageUrl -ReplyUrls $appReplyURLs -PasswordCredentials $PasswordCredential
  $logo = Join-Path (Get-Location) '\Config\Harden365App.jpg'
  $HardenAppId = $HardenApp.AppId
  Set-AzureADApplicationLogo -ObjectId $HardenApp.ObjectId -FilePath $logo 
}
#endregion

#Get Service Principal of Microsoft Graph Resource API
$Harden365App = Get-AzureADApplication -Filter "DisplayName eq 'Harden365 App'"
$graphSP = Get-AzureADServicePrincipal -All $true | Where-Object { $_.DisplayName -eq 'Microsoft Graph' }
 
#Initialize RequiredResourceAccess for Microsoft Graph Resource API 
$requiredGraphAccess = New-Object Microsoft.Open.AzureAD.Model.RequiredResourceAccess
$requiredGraphAccess.ResourceAppId = $graphSP.AppId
$requiredGraphAccess.ResourceAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess]
 
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
  'Group.ReadWrite.All')
 
#Add app permissions
ForEach ($permission in $ApplicationPermissions) {
  $reqPermission = $null
  #Get required app permission
  $reqPermission = $graphSP.AppRoles | Where-Object { $_.Value -eq $permission }
  if ($reqPermission) {
    $resourceAccess = New-Object Microsoft.Open.AzureAD.Model.ResourceAccess
    $resourceAccess.Type = 'Role'
    $resourceAccess.Id = $reqPermission.Id    
    #Add required app permission
    $requiredGraphAccess.ResourceAccess.Add($resourceAccess)
  }
  else {
    Write-Host "App permission $permission not found in the Graph Resource API" -ForegroundColor Red
  }
}
 
<# Set Delegated Permissions
$DelegatedPermissions = @('Directory.Read.All', 'Group.ReadWrite.All') #Leave it as empty array if not required
 
#Add delegated permissions
ForEach ($permission in $DelegatedPermissions) {
$reqPermission = $null
#Get required delegated permission
$reqPermission = $graphSP.Oauth2Permissions | Where-Object {$_.Value -eq $permission}
if($reqPermission)
{
$resourceAccess = New-Object Microsoft.Open.AzureAD.Model.ResourceAccess
$resourceAccess.Type = "Scope"
$resourceAccess.Id = $reqPermission.Id    
#Add required delegated permission
$requiredGraphAccess.ResourceAccess.Add($resourceAccess)
}
else
{
Write-Host "Delegated permission $permission not found in the Graph Resource API" -ForegroundColor Red
}
}
#>

 
#Add required resource accesses
$requiredResourcesAccess = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.RequiredResourceAccess]
$requiredResourcesAccess.Add($requiredGraphAccess)
 
#Set permissions in existing Azure AD App
$appObjectId = $Harden365App.ObjectId
Set-AzureADApplication -ObjectId $appObjectId -RequiredResourceAccess $requiredResourcesAccess