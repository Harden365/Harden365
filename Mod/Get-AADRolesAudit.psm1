
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
</style>
"@

$RolesCollection = @()
$Roles = Get-AzureADDirectoryRole
ForEach ($Role In $Roles){
  $Members = Get-AzureADDirectoryRoleMember -ObjectId $Role.ObjectId
  ForEach ($Member In $Members) {
    $obj = New-Object PSObject -Property @{
      ObjectId = $Member.ObjectId
      RoleName = $Role.DisplayName
      Name = $Member.DisplayName
      UserPrincipalName = $Member.UserPrincipalName
      MemberType = $Member.UserType
      Enabled = $Member.AccountEnabled
      WhenCreated = ($Member.ExtensionProperty).createdDateTime
    }
    $RolesCollection += $obj
  }
}

#GENERATE HTML
mkdir -Force ".\Audit" | Out-Null
$dateFileString = Get-Date -Format "FileDateTimeUniversal"
$RolesCollection | Sort-Object UserPrincipalName,RoleName | ConvertTo-Html -Property RoleName,Enabled,UserPrincipalName,Name,WhenCreated `
    -PreContent "<h1>Audit Roles and Administrators</h1>" "<h2>$DomainOnM365</h2>" -Head $Header -Title "Harden 365 - Audit" -PostContent "<h2>$(Get-Date -UFormat "%d-%m-%Y %T ")</h2>"`
    | foreach {
    $PSItem -replace "<td>Global Administrator</td>", "<td style='color: #cc0000;font-weight: bold'>Global Administrator</td>"
    } | Out-File .\Audit\Harden365-AuditRoles$dateFileString.html

Invoke-Expression .\Audit\Harden365-AuditRoles$dateFileString.html
Write-LogInfo "Audit Roles Administration generated"
Write-LogSection '' -NoHostOutput
}

