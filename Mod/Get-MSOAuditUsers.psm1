
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

    Write-LogSection 'AUDIT USERS' -NoHostOutput

    #SCRIPT

    $DomainOnM365 = (Get-MsolDomain | Where-Object { $_.IsInitial -match $true }).Name

    #TENANT EDITION
    if (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne '0' } | Select-Object -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match 'AAD_PREMIUM_P2') {
        $TenantEdition = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne '0' } | Select-Object -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match 'AAD_PREMIUM_P2' }).ServiceName
        $TenantEdition = 'Azure AD Premium P2' 
    }    
    elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne '0' } | Select-Object -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match 'AAD_PREMIUM') {
        $TenantEdition = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne '0' } | Select-Object -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match 'AAD_PREMIUM' }).ServiceName
        $TenantEdition = 'Azure AD Premium P1' 
    }  

    $header = @'
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
'@




    $Users = Get-MsolUser -All | Where-Object { $_.IsLicensed -eq $true } | Select-Object UserPrincipalName, WhenCreated, ImmutableId, LastPasswordChangeTimestamp, PasswordNeverExpires, StrongAuthenticationMethods, `
    @{Name = 'PhoneNumbers'; Expression = { ($_.StrongAuthenticationUserDetails).PhoneNumber } },
    @{Name = 'LicensePlans'; Expression = { (($_.licenses).Accountsku).SkupartNumber } }

    $ExportUsers = @()
    Try {
        foreach ($user in $Users) {
            $UPN = $user.UserPrincipalName
            Write-LogInfo "Check $UPN"
            Start-Sleep -Seconds 1
            if ($null -ne $TenantEdition) {
                try {
                    $LastLogon = (Get-AzureADAuditSignInLogs -top 1 -Filter "UserPrincipalName eq '$UPN'").CreatedDateTime
                }
                catch {
                    $LastLogon = 'N/A' 
                }
            }


            $LicenseNames = $user.LicensePlans
            Switch -Wildcard ($LicenseNames) {
                '*FLOW_FREE' {
                    $LicenseNames = 'Microsoft Power Automate Free' 
                }
                '*TEAMS_EXPLORATORY' {
                    $LicenseNames = 'Microsoft Teams Exploratory' 
                }
                '*PHONESYSTEM_VIRTUALUSER' {
                    $LicenseNames = 'Microsoft Teams Exploratory' 
                }
                '*STREAM' {
                    $LicenseNames = '' 
                }
                '*POWER_BI_STANDARD' {
                    $LicenseNames = '' 
                }
                '*POWERAPPS_VIRAL' {
                    $LicenseNames = '' 
                }
                '*TEAMS_COMMERCIAL_TRIAL' {
                    $LicenseNames = '' 
                }
                '*STANDARDPACK' {
                    $LicenseNames = 'Office 365 E1' 
                }
                '*POWER_BI_PRO' {
                    $LicenseNames = 'PowerBI Pro' 
                }
                '*EXCHANGESTANDARD' {
                    $LicenseNames = 'ExchangeOnline P1' 
                }
                '*O365_BUSINESS_PREMIUM' {
                    $LicenseNames = 'M365 Business Standard' 
                }
                '*O365_BUSINESS_ESSENTIALS' {
                    $LicenseNames = 'M365 Business Basic' 
                }
                '*DYN365_ENTERPRISE_SALES' {
                    $LicenseNames = 'Dyn365 Sales Enterprise Edition' 
                }
                '*DYN365_TEAM_MEMBERS' {
                    $LicenseNames = 'Dyn365 Team Members' 
                }
                '*PROJECTPROFESSIONAL' {
                    $LicenseNames = 'Project Professional P3' 
                }
                '*EXCHANGEENTERPRISE' {
                    $LicenseNames = 'ExchangeOnline P2' 
                }
                '*OFFICESUBSCRIPTION' {
                    $LicenseNames = 'Microsoft 365 Apps for enterprise' 
                }
                '*SPB' {
                    $LicenseNames = 'M365 Business Premium' 
                }
                default {
                    $licenseNames = $licenseNames 
                }
            }

            $MFAMethod = (($user.StrongAuthenticationMethods) | Where-Object { $_.IsDefault -eq $true }).MethodType
            Switch ($MFAMethod) {
                'OneWaySMS' {
                    $MFAMethod = 'SMS token' 
                }
                'TwoWayVoiceMobile' {
                    $MFAMethod = 'Phone call verification' 
                }
                'PhoneAppOTP' {
                    $MFAMethod = 'Hardware token or authenticator app' 
                }
                'PhoneAppNotification' {
                    $MFAMethod = 'Authenticator app' 
                }
            }

            $Props = @{
                'Check'               = if (($user.PasswordNeverExpires -eq $true) -and (!$user.StrongAuthenticationMethods)) {
                    'Warning'
                }
                else {
                    'Healthy'
                }
                'UserPrincipalName'   = $user.UserPrincipalName 
                'When Created'        = $user.WhenCreated
                'Password LastChange' = $user.LastPasswordChangeTimestamp
                'Never Expire'        = $user.PasswordNeverExpires
                'Last Logon (30d)'    = $LastLogon
                'Licenses'            = $LicenseNames
                'AD Sync'             = if ($user.ImmutableId) {
                    $True
                }
                else {
                    $False
                }
                'MFA CONFIGURED'      = if ($user.StrongAuthenticationMethods) {
                    $True
                }
                else {
                    $False
                }
                'MFA PRIMARY METHOD'  = $MFAMethod
                'MFA PER USER'        = if ($user.StrongAuthenticationRequirements) {
                    $True
                }
                else {
                    $False
                }
                'Phone Number'        = $user.PhoneNumbers
            }
            $ExportUsers += New-Object PSObject -Property $Props
        }
    }
    catch {
        Write-LogError ' Users Collection building error'
    }
     
    $dateFileString = Get-Date -Format 'FileDateTimeUniversal'
    mkdir -Force '.\Audit' | Out-Null
    $ExportUsers | Sort-Object UserPrincipalName, Licenses | Select-Object 'Check', UserPrincipalName, Licenses, 'Ad Sync', 'Never Expire', 'Last Logon (30d)', 'Password LastChange', 'MFA PER USER', 'MFA CONFIGURED', 'MFA PRIMARY METHOD', 'Phone Number', 'When Created'`
    | Export-Csv -Path ".\Audit\AuditUsersDetails$dateFileString.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation


    #GENERATE HTML
    $ExportUsers | Sort-Object UserPrincipalName, Licenses, 'AD Sync', 'Last Logon (30d)', 'Never Expire', 'Password LastChange', 'MFA PER USER', 'MFA CONFIGURED', 'MFA PRIMARY METHOD', 'Phone Number', 'When Created' | ConvertTo-Html -Property 'Check', UserPrincipalName, Licenses, 'AD Sync', 'Last Logon (30d)', 'Never Expire', 'Password LastChange', 'MFA PER USER', 'MFA CONFIGURED', 'MFA PRIMARY METHOD', 'Phone Number', 'When Created' `
        -PreContent '<h1>Audit Users Detail</h1>' "<h2>$DomainOnM365</h2>" -Head $Header -PostContent "<h2>$(Get-Date)</h2>"`
    | ForEach-Object { $PSItem -replace '<td>Warning</td>', "<td style='color: #cc0000;font-weight: bold'>Warning</td>" }`
    | ForEach-Object { $PSItem -replace '<td>Healthy</td>', "<td style='color: #32cd32;font-weight: bold'>Healthy</td>" }`
    | Out-File .\Audit\Harden365-AuditUsersDetails$dateFileString.html

    Invoke-Expression .\Audit\Harden365-AuditUsersDetails$dateFileString.html 
    Write-LogInfo 'Audit Users Detail generated in folder .\Audit'
    Write-LogSection '' -NoHostOutput 
}

