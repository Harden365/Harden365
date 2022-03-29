<#
.DESCRIPTION
    All audit function requesting Azure AD
.NOTES
    Author:       Community Harden - contact@harden365.net
    Created On:   09/28/2021
    Last Updated: 11/26/2021
    Version:      v0.5
#>

<#
.DESCRIPTION
    Export all Azure AD DNS Records for all tenant domains in a CSV file
.NOTES
    Author:       Community Harden - contact@harden365.net
    Created On:   09/28/2021
    Last Updated: 11/26/2021
    Version:      v0.5
    
    Azure AD PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-AzureADDNSRecordsCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-AzureADDNSRecordsCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all Azure domains'' service configuration'
    
    $allDNSRecords = Get-AzureADDomain | Get-AzureADDomainServiceConfigurationRecord  |`
    select DnsRecordId, IsOptional, Label, RecordType, SupportedService, Ttl, MailExchange, `
    Preference, Text, CanonicalName, NameTarget, Port, Priority, Protocol, Service, Weight
    Write-LogInfo "$($allDNSRecords.Count) DNS records found"
    
    $exportFullPath = "$pwd\Audit\$ExportName\AzureADDNSRecords-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $allDNSRecords | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $allDNSRecords
}

<#
.DESCRIPTION
    Export all Azure AD users in a CSV file
.NOTES
    Author:       Community Harden - contact@harden365.net
    Created On:   09/28/2021
    Last Updated: 11/26/2021
    Version:      v0.5

    Azure AD PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-AzureADUsersCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-AzureADUsersCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all users'
    $allUsers = Get-AzureADUser -All $true | Select ObjectType, Mail, UserPrincipalName, UserType, AccountEnabled, AgeGroup, City, CompanyName, ConsentProvidedForMinor, Country, CreationType, Department, DirSyncEnabled, DisplayName, FacsimileTelephoneNumber, GivenName, IsCompromised, ImmutableId, JobTitle, LastDirSyncTime, LegalAgeGroupClassification, MailNickName, Mobile, OnPremisesSecurityIdentifier, PasswordPolicies, PasswordProfile, PhysicalDeliveryOfficeName, PostalCode, PreferredLanguage, ProxyAddresses[0], RefreshTokensValidFromDateTime, ShowInAddressList, SipProxyAddress, State, StreetAddress, Surname, TelephoneNumber, UsageLocation, UserState, UserStateChangedOn, AssignedLicenses

    Write-LogInfo "$($allUsers.Count) users in AAD found"
    
    $exportFullPath = "$pwd\Audit\$ExportName\AzureADUsersCSVExport-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $allUsers | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $allUsers
}

<#
.DESCRIPTION
    Export all Azure / Microsoft 365 licences in a CSV file and returns Skus

.NOTES
    Author:       Community Harden - contact@harden365.net
    Created On:   09/28/2021
    Last Updated: 11/26/2021
    Version:      v0.5

    Source/Inspiration : https://docs.microsoft.com/fr-fr/office365/enterprise/powershell/view-account-license-and-service-details-with-office-365-powershell
    Azure AD PowerShell Module required,
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-AzureADPlanCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-AzureADPlanCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all SKU'
    $allSKUs=Get-AzureADSubscribedSku
    $allServicePlans = $allSKUs | Select * -ExpandProperty ServicePlans -ea SilentlyContinue |`
     Select SkuPartNumber, SkuId, AppliesTo, ProvisioningStatus, CapabilityStatus, ConsumedUnits,  ServicePlanId, ServicePlanName -ExpandProperty PrepaidUnits

    Write-LogInfo "$($allServicePlans.Count) Service plans found"

    $exportFullPath = "$pwd\Audit\$ExportName\AzureADPlan-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $allServicePlans | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $allSKUs
}

<#
.DESCRIPTION
    Export all Azure AD users' licences in a CSV file in current folder
.NOTES
    Author:       Community Harden - contact@harden365.net
    Created On:   09/28/2021
    Last Updated: 11/26/2021
    Version:      v0.5
    Source/Inspiration : https://docs.microsoft.com/fr-fr/office365/enterprise/powershell/view-account-license-and-service-details-with-office-365-powershell
    Azure AD PowerShell Module required,
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.PARAMETER AllUsers
    List of all AD Users
.PARAMETER LicensePlanList
    List of all SKUs
.EXAMPLE
    Get-AzureADUsersLicencesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z' -AllUsers (Get-AzureADUser) -LicensePlanList (Get-AzureADSubscribedSku)
#>
function Get-AzureADUsersLicencesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString,
        [Parameter(Mandatory = $true)]
        $AllUsers,
        [Parameter(Mandatory = $true)]
        $LicensePlanList
    )

    $allExpandedUsers = $AllUsers | Select * -ExpandProperty AssignedLicenses | `
    Select ObjectType, Mail, UserPrincipalName, CompanyName, UserType, AccountEnabled, SkuId, `
    @{Name = 'DisabledPlansCount'; Expression = {($_.DisabledPlans).Count}}

    Write-LogInfo 'Join Users/SKU'
    $allUsersPlans = @()
    $allExpandedUsers | % { 
        $sku=$_.SkuId ; $user = $_;  $LicensePlanList | % { 
            If ( $sku -eq $_.ObjectId.substring($_.ObjectId.length - 36, 36) ) 
            { 
                # Collect information into a hashtable
                $Props = @{
                    "ObjectType" =  $user.ObjectType
                    "Mail" =  $user.Mail
                    "Company" = $user.CompanyName
                    "UserPrincipalName" =  $user.UserPrincipalName
                    "UserType" =  $user.UserType
                    "AccountEnabled" =  $user.AccountEnabled
                    "SkuPartNumber" =  $_.SkuPartNumber
                    "SkuId" =  $_.SkuId
                } 
                $allUsersPlans += New-Object PSObject -Property $Props
            }
        }
    }

    Write-LogInfo "$($allUsersPlans.Count) plans X users found"

    $exportFullPath = "$pwd\Audit\$ExportName\AzureADUsersLicences-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $allUsersPlans | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $allUsersPlans
}

<#
.DESCRIPTION
    Get last users sign in
.NOTES
    Author:       Community Harden - contact@harden365.net
    Created On:   09/28/2021
    Last Updated: 11/26/2021
    Version:      v0.5

    Source/Inspiration : https://docs.microsoft.com/fr-fr/office365/enterprise/powershell/view-account-license-and-service-details-with-office-365-powershell
    Azure AD PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-UsersSignInCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-UsersSignInCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )
    
    Write-LogInfo 'Request all signin activities'
    $usersSignIns = Get-AzureADAuditSignInLogs -All $true | select UserPrincipalName, CreatedDateTime, ConditionalAccessStatus, AppDisplayName,`
        @{ Name='StatusErrorCode'; Expression={$_.Status.ErrorCode}}, @{ Name='StatusFailureReason'; Expression={$_.Status.FailureReason}}, `
        @{ Name='StatusAdditionalDetails'; Expression={$_.Status.AdditionalDetails}}, @{ Name='City'; Expression={$_.Location.City}}, `
        @{ Name='State'; Expression={$_.Location.State}}, @{ Name='CountryOrRegion'; Expression={$_.Location.CountryOrRegion}}, `
        @{ Name='AuthMethod'; Expression={$_.MfaDetail.AuthMethod}},@{ Name='AuthDetail'; Expression={$_.MfaDetail.AuthDetail}}

    Write-LogInfo "$($usersSignIns.Count) user signin logs found"

    $exportFullPath = "$pwd\Audit\$ExportName\UsersSignIn-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $usersSignIns | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $usersSignIns
}

<#
.DESCRIPTION
    Export all Azure AD groups in a CSV file
.NOTES
    Author:       Community Harden - contact@harden365.net
    Created On:   09/28/2021
    Last Updated: 11/26/2021
    Version:      v0.5

    Source/Inspiration : https://docs.microsoft.com/fr-fr/office365/enterprise/powershell/view-account-license-and-service-details-with-office-365-powershell
    Azure AD PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-AzureADGroupsCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-AzureADGroupsCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )
    
    Write-LogInfo 'Request all AD Groups'
    $allGroups = Get-AzureADMSGroup -All $true | select *, @{N="GroupType"; E={ if( $_.GroupTypes -ne $null){ `
                    $_.GroupTypes[0]} else {"DistributionList"}}}
    
    Write-LogInfo "$($allGroups.Count) AD groups found"

    $exportFullPath = "$pwd\Audit\$ExportName\AzureADGroups-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $allGroups | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $allGroups
}