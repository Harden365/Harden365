
###################################################################
## Get-AADRolesAudit                                             ##
## ---------------------------                                   ##
## This function will audit roles adminsitation in AAD           ##
## and export result in html                                     ##
##                                                               ##
## Version: 01.00.000                                            ##
##  Author: contact@harden365.net                                ##
###################################################################
Function Get-AADRolesAudit {

#SCRIPT
Write-LogSection 'AUDIT ROLES' -NoHostOutput
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name


$header = @"
<img src="$pwd\Config\Harden365.logohtml" alt="logoHarden365" class="centerImage" alt="CH Logo" height="167" width="500">
<style>
    h1 {
        font-family: Arial, Helvetica, sans-serif;
        color: #cc0000;
        font-size: 28px;
        text-align:center;
    }
    h2 {
        font-family: Arial, Helvetica, sans-serif;
        color: #000099;
        font-size: 16px;
        text-align:right;
    }
   table {
        margin: auto;
        font-size: 12px;
		border: 0px; 
		font-family: Arial, Helvetica, sans-serif;
	} 
    td {
        padding: 4px;
		margin: 0px;
		border: 0;
	}
    th {
        background: #395870;
        background: linear-gradient(#49708f, #293f50);
        color: #fff;
        font-size: 11px;
        text-transform: uppercase;
        padding: 10px 15px;
        vertical-align: middle;
	}
    tbody tr:nth-child(even) {
        background: #f0f0f2;
    }
    .footer
    { color:green;
    margin-left:25px;
    font-family:Tahoma;
    font-size:8pt;
    }
</style>
"@


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
$Users = Get-MsolUser -All | Select ObJectId,LastPasswordChangeTimestamp,PasswordNeverExpires,ImmutableId,StrongAuthenticationMethods, `
                                                                        @{Name = 'PhoneNumbers'; Expression = {($_.StrongAuthenticationUserDetails).PhoneNumber}},
                                                                        @{Name = 'LicensePlans'; Expression = {(($_.licenses).Accountsku).SkupartNumber}}
          foreach ($user in $Users) {
          $objuser = New-Object PSObject -Property @{
          #LastLogon = Get-AzureAdAuditSigninLogs -top 1 -Filter "userDisplayName eq '$user'" | select CreatedDateTime
          ObjectId = $user.ObjectId
          IsLicensed = if ($user.LicensePlans) {$True} else {$False}
          ADSync = if ($user.ImmutableId) {$True} else {$False}
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
        $obj | Add-Member -MemberType NoteProperty -Name 'ADSync' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).ADSync
        $obj | Add-Member -MemberType NoteProperty -Name 'MFAEnabled' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).MFAEnabled
        $obj | Add-Member -MemberType NoteProperty -Name 'MFAMethod' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).MFAMethod
        $obj | Add-Member -MemberType NoteProperty -Name 'MFAEnforced' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).MFAEnforced
        $obj | Add-Member -MemberType NoteProperty -Name 'PhoneNumbers' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).PhoneNumbers
        $obj | Add-Member -MemberType NoteProperty -Name 'IsLicensed' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).IsLicensed
    }
}

$Export = $RolesCollection | Where-Object {$_.MemberType -ne $null} | Sort-Object UserPrincipalName,RoleName


#GENERATE HTML
mkdir -Force ".\Audit" | Out-Null
$dateFileString = Get-Date -Format "FileDateTimeUniversal"
$export | ConvertTo-Html -Property RoleName,Enabled,UserPrincipalName,Name,IsLicensed,ADSync,PasswordNeverExpires,PasswordLastChange,MFAEnforced,MFAEnabled,MFAMethod,PhoneNumbers,WhenCreated `
    -PreContent "<h1>Audit Roles and Administrators</h1>" "<h2>$DomainOnM365</h2>" -Head $Header -Title "Harden 365 - Audit" -PostContent "<h2>$(Get-Date -UFormat "%d-%m-%Y %T ")</h2>"`
    | foreach {$PSItem -replace "<td>Global Administrator</td>", "<td style='color: #cc0000;font-weight: bold'>Global Administrator</td>"}`
    | Out-File .\Audit\Harden365-AuditRoles$dateFileString.html

Invoke-Expression .\Audit\Harden365-AuditRoles$dateFileString.html
Write-LogInfo "Audit Roles Administration generated"
Write-LogSection '' -NoHostOutput
}

