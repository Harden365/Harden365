<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.CAExport.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 01/18/2021
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Conditional Access Export Users List

    .DESCRIPTION
        Export Users List
#>


Function Get-MSOUsersList {
     <#
        .Synopsis
         Export Users List
        
        .Description
         This function will audit users details in AAD and export result in csv 
        
        .Notes
         Version: 01.00 -- 
         
    #>



#SCRIPT
Write-LogSection 'EXPORT USERS LIST' -NoHostOutput
$DomainOnM365=(Get-MsolDomain | Where-Object { $_.IsInitial -match $true }).Name

$Users = Get-MsolUser -All | Where-Object {$_.IsLicensed -eq $true} | Select UserPrincipalName,WhenCreated,LastPasswordChangeTimestamp,PasswordNeverExpires,StrongAuthenticationMethods, `
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

            $MFAMethod = (($user.StrongAuthenticationMethods) | ? {$_.IsDefault -eq $true}).MethodType
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
                "MFA Enabled" = if ($user.StrongAuthenticationMethods) {$True} else {$False}
                "MFA Method" = $MFAMethod
                "MFA Enforced" = if ($user.StrongAuthenticationRequirements) {$True} else {$False}
                "PhoneNumbers" =  $user.PhoneNumbers
                }
                $ExportUsers += New-Object PSObject -Property $Props
                }
     
$dateFileString = Get-Date -Format "FileDateTimeUniversal"
mkdir -Force ".\Input" | Out-Null
$ExportUsers | Sort-Object  UserPrincipalName,Licenses | Select-object UserPrincipalName,Licenses,"When Created","Password LastChange","Password NeverExpires","MFA Enabled","MFA Enforced","MFA Method",PhoneNumbers,ImportPhoneNumber | Export-Csv -Path `
".\Input\ImportPhoneNumbers.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation
Write-LogInfo "Extract Users Detail to CSV in folder .\Input"

Write-LogSection '' -NoHostOutput      
}

