
###################################################################
## Get-AADRolesAudit                                             ##
## ---------------------------                                   ##
## This function will audit roles adminsitation in AAD           ##
## and export result in html                                     ##
##                                                               ##
## Version: 01.00.000                                            ##
##  Author: contact@harden365.net                                ##
###################################################################

# Cloud - GlobalAdmin - Enable - MFA - Licence
Function Get-AADRolesAudit {

#SCRIPT
Write-LogSection 'AUDIT ROLES' -NoHostOutput
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name

$RolesCollection = @()
$Roles = Get-AzureADDirectoryRole
ForEach ($Role In $Roles){
  $Members = Get-AzureADDirectoryRoleMember -ObjectId $Role.ObjectId 
  ForEach ($Member In $Members) {
    $objrole = New-Object PSObject -Property @{
      ObjectId = $Member.ObjectId
      RoleName = $Role.DisplayName
      Name = $Member.DisplayName
      UserPrincipalName = $Member.UserPrincipalName
      MemberType = $Member.UserType
      Enabled = $Member.AccountEnabled
      WhenCreated = ($Member.ExtensionProperty).createdDateTime
      }
      $RolesCollection += $objrole
  }
}

$UsersCollection = @()
$Users = Get-MsolUser -All | Select ObJectId,LastPasswordChangeTimestamp,PasswordNeverExpires,StrongAuthenticationMethods, `
                                                                        @{Name = 'PhoneNumbers'; Expression = {($_.StrongAuthenticationUserDetails).PhoneNumber}},
                                                                        @{Name = 'LicensePlans'; Expression = {(($_.licenses).Accountsku).SkupartNumber}}
          foreach ($user in $Users) {
          $objuser = New-Object PSObject -Property @{
          ObjectId = $user.ObjectId
          IsLicensed = if ($user.LicensePlans) {$True} else {$False}
          PasswordNeverExpires = $user.PasswordNeverExpires
          PasswordLastChange =  $user.LastPasswordChangeTimestamp
          MFAEnforced = $(if ($user.StrongAuthenticationRequirements) {$True} else {$False})
          MFAEnabled = if ($user.StrongAuthenticationMethods) {$True} else {$False}
          MFAMethod = (($user.StrongAuthenticationMethods) | ? {$_.IsDefault -eq $true}).MethodType
          PhoneNumbers =  $user.PhoneNumbers
          }
          $UsersCollection += $objuser
  }
  
foreach ($item in $RolesCollection) {
    foreach ($obj in $item) {
        $obj | Add-Member -MemberType NoteProperty -Name 'PasswordLastChange' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).PasswordLastChange
        $obj | Add-Member -MemberType NoteProperty -Name 'StrongAuthenticationMethod' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).StrongAuthenticationMethod
        $obj | Add-Member -MemberType NoteProperty -Name 'PasswordNeverExpires' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).PasswordNeverExpires
        $obj | Add-Member -MemberType NoteProperty -Name 'MFAEnabled' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).MFAEnabled
        $obj | Add-Member -MemberType NoteProperty -Name 'MFAMethod' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).MFAMethod
        $obj | Add-Member -MemberType NoteProperty -Name 'MFAEnforced' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).MFAEnforced
        $obj | Add-Member -MemberType NoteProperty -Name 'PhoneNumbers' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).PhoneNumbers
        $obj | Add-Member -MemberType NoteProperty -Name 'IsLicensed' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).IsLicensed
    }
}

$Export = $RolesCollection | Where-Object {$_.MemberType -ne $null}

#GENERATE HTML
mkdir -Force ".\Audit" | Out-Null
$dateFileString = Get-Date -Format "FileDateTimeUniversal"
$export | Sort-Object UserPrincipalName,RoleName | ConvertTo-Html -Property RoleName,Enabled,UserPrincipalName,Name,WhenCreated,PasswordNeverExpires,PasswordLastChange,MFAEnforced,MFAEnabled,MFAMethod,PhoneNumbers `
    -PreContent "<h1>Audit Roles and Administrators</h1>" "<h2>$DomainOnM365</h2>" -Head $Header -Title "Harden 365 - Audit" -PostContent "<h2>$(Get-Date -UFormat "%d-%m-%Y %T ")</h2>"`
    | foreach {
    $PSItem -replace "<td>Global Administrator</td>", "<td style='color: #cc0000;font-weight: bold'>Global Administrator</td>"
    } | Out-File .\Audit\Harden365-AuditRoles$dateFileString.html

Invoke-Expression .\Audit\Harden365-AuditRoles$dateFileString.html
Write-LogInfo "Audit Roles Administration generated"
Write-LogSection '' -NoHostOutput
}






# CompanyDomain - Name - ADSync - PWDSync
(Get-MsolCompanyInformation).DisplayName
(Get-MsolCompanyInformation).InitialDomain
(Get-MsolCompanyInformation).DirectorySynchronizationEnabled
(Get-MsolCompanyInformation).DirSyncServiceAccount
(Get-MsolCompanyInformation).LastDirSyncTime
(Get-MsolCompanyInformation).PasswordSynchronizationEnabled
(Get-MsolCompanyInformation).AuthorizedServiceInstances
(Get-MsolCompanyInformation).DapEnabled

(Get-MsolCompanyInformation).PasswordSynchronizationEnabled
(Get-MsolCompanyInformation).UsersPermissionToCreateGroupsEnabled
(Get-MsolCompanyInformation).UsersPermissionToCreateLOBAppsEnabled
(Get-MsolCompanyInformation).UsersPermissionToUserConsentToAppEnabled
(Get-MsolCompanyInformation).UsersPermissionToReadOtherUsersEnabled

# version Azure AD Tenant
Get-AzureADSubscribedSku


(Get-OrganizationConfig).Name
(Get-OrganizationConfig).SharePointUrl

(Get-OrganizationConfig).HiddenMembershipGroupsCreationEnabled  
(Get-OrganizationConfig).DefaultGroupAccessType 
(Get-OrganizationConfig).CustomerLockboxEnabled 

Set-OrganizationConfig -CustomerLockboxEnabled $true