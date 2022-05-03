
###################################################################
## Get-MSOAuditUsers                                             ##
## ---------------------------                                   ##
## This function will audit users details in AAD                 ##
## and export result in html and csv                             ##
##                                                               ##
## Version: 01.00.000                                            ##
##  Author: contact@harden365.net                                ##
###################################################################
Function Get-MSOAuditUsers {
     <#
        .Synopsis
         Audit Users Details
        
        .Description
         ## This function will audit users details in AAD and export result in html and csv
        
        .Notes
         Version: 01.00 -- 
         
    #>



#SCRIPT

$DomainOnM365=(Get-MsolDomain | Where-Object { $_.IsInitial -match $true }).Name

$header = @"
<img src="..\Config\Harden365.logohtml" alt="logoHarden365" class="centerImage" alt="CH Logo" height="167" width="500">
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
    h3 {
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




$Users = Get-MsolUser -All | Where-Object {$_.IsLicensed -eq $true} | Select-Object UserPrincipalName,WhenCreated,ImmutableId,LastPasswordChangeTimestamp,PasswordNeverExpires,StrongAuthenticationMethods, `
                                                                        @{Name = 'PhoneNumbers'; Expression = {($_.StrongAuthenticationUserDetails).PhoneNumber}},
                                                                        @{Name = 'LicensePlans'; Expression = {(($_.licenses).Accountsku).SkupartNumber}}

$ExportUsers = @()
          foreach ($user in $Users) {

            $LicenseNames = $user.LicensePlans
            Switch -Wildcard ($LicenseNames) {
                   "*FLOW_FREE" { $LicenseNames = "" }
                   "*TEAMS_EXPLORATORY" { $LicenseNames = "" }
                   "*STREAM" { $LicenseNames = "" }
                   "*POWER_BI_STANDARD" { $LicenseNames = "" }
                   "*POWERAPPS_VIRAL" { $LicenseNames = "" }
                   "*TEAMS_COMMERCIAL_TRIAL" { $LicenseNames = "" }
                   "*POWER_BI_PRO" { $LicenseNames = "PowerBI Pro" }
                   "*EXCHANGESTANDARD" { $LicenseNames = "ExchangeOnline P1" }
                   "*O365_BUSINESS_PREMIUM" { $LicenseNames = "M365 Business Standard" }
                   "*DYN365_ENTERPRISE_SALES" { $LicenseNames = "Dyn365 Sales Enterprise Edition" }
                   "*DYN365_TEAM_MEMBERS" { $LicenseNames = "Dyn365 Team Members" }
                   "*PROJECTPROFESSIONAL" { $LicenseNames = "Project Professional P3" }
                   "*EXCHANGEENTERPRISE" { $LicenseNames = "ExchangeOnline P2" }
                   "*OFFICESUBSCRIPTION" { $LicenseNames = "Microsoft 365 Apps for enterprise" }
                   "*SPB" { $LicenseNames = "M365 Business Premium" }
                   default { $licenseNames = $licenseNames }
                    }

            $MFAMethod = (($user.StrongAuthenticationMethods) | Where-Object {$_.IsDefault -eq $true}).MethodType
            Switch ($MFAMethod) {
                   "OneWaySMS" { $MFAMethod = "SMS token" }
                   "TwoWayVoiceMobile" { $MFAMethod = "Phone call verification" }
                   "PhoneAppOTP" { $MFAMethod = "Hardware token or authenticator app" }
                   "PhoneAppNotification" { $MFAMethod = "Authenticator app" }
                    }

               $Props = @{
                "UserPrincipalName" =  $user.UserPrincipalName
                "When Created" =  $user.WhenCreated
                "Password LastChange" =  $user.LastPasswordChangeTimestamp
                "Password NeverExpires" = $user.PasswordNeverExpires
                "Licenses" = $LicenseNames
                "ADSync" = if ($user.ImmutableId) {$True} else {$False}
                "MFA Enabled" = if ($user.StrongAuthenticationMethods) {$True} else {$False}
                "MFA Method" = $MFAMethod
                "MFA Enforced" = if ($user.StrongAuthenticationRequirements) {$True} else {$False}
                "PhoneNumbers" =  $user.PhoneNumbers
                }
                $ExportUsers += New-Object PSObject -Property $Props
                }
     
$dateFileString = Get-Date -Format "FileDateTimeUniversal"
mkdir -Force ".\Audit" | Out-Null
$ExportUsers | Sort-Object  UserPrincipalName,Licenses | Select-object UserPrincipalName,Licenses,AdSync,"When Created","Password LastChange","Password NeverExpires","MFA Enabled","MFA Enforced","MFA Method",PhoneNumbers | Export-Csv -Path `
".\Audit\AuditUsersDetails$dateFileString.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation


#GENERATE HTML
$ExportUsers | Sort-Object  UserPrincipalName,Licenses,ADSync,"When Created","Password LastChange","Password NeverExpires","MFA Enabled","MFA Enforced","MFA Method",PhoneNumbers | ConvertTo-Html -Property  UserPrincipalName,Licenses,ADSync,"When Created","Password LastChange","Password NeverExpires","MFA Enabled","MFA Enforced","MFA Method",PhoneNumbers `
    -PreContent "<h1>Audit Users Detail</h1>" "<h2>$DomainOnM365</h2>" -Head $Header -Title "OGIC - Audit" -PostContent "<h2>$(Get-Date)</h2>"`
    | Out-File .\Audit\Harden365-AuditUsersDetails$dateFileString.html

Invoke-Expression .\Audit\Harden365-AuditUsersDetails$dateFileString.html  
}

