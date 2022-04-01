<#
.DESCRIPTION
    All audit function requesting based on MSOL module
.NOTES
    Author:       Community Harden - contact@harden365.net
    Created On:   09/28/2021
    Last Updated: 11/26/2021
    Version:      v0.5
#>

<#
.DESCRIPTION
    Export all Azure AD users' MFA status in CSV
.NOTES
    MSOL PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-MsolUsersMFAStatusCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-MsolUsersMFAStatusCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $false)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all accounts MFA status roles'
    
    $msolUsersWithMFAStatus = Get-MsolUser -all | select UserPrincipalName, UserType, ObjectId, WhenCreated, `
    LastPasswordChangeTimestamp, PasswordNeverExpires, PasswordResetNotRequiredDuringActivate, `
    ValidationStatus, IsLicensed, BlockCredential, `
    @{N="MFAStatus"; E={ if( $_.StrongAuthenticationRequirements.State -ne $null) `
        { $_.StrongAuthenticationRequirements.State} else { "Disabled"}}}, `
    @{N="MFAMethod"; E={ if( $_.StrongAuthenticationMethods.MethodType -ne $null){ `
        $_.StrongAuthenticationMethods.MethodType}}}, StrongPasswordRequired, `
        StrongAuthenticationProofupTim

    Write-LogInfo "$($msolUsersWithMFAStatus.Count) accounts found"
    
    $exportFullPath = ".\Audit\MsolUsersMFAStatus.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $msolUsersWithMFAStatus | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $msolUsersWithMFAStatus
}


<#
.DESCRIPTION
    Export all M365 users' admin role infos in a CSV file in current folder, including MFA authentication status in CSV file
.NOTES
    MSOL PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.PARAMETER List of users with MFA status containing a colum named 'UserPrincipalName' containing user's full email address.
    Date Identifier
.EXAMPLE
    Get-MsolAdminRolesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z' -MsolUsersWithMFAStatus (Get-MsolUser -all)
#>
function Get-MsolAdminRolesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString,
        [Parameter(Mandatory = $false)]
        $MsolUsersWithMFAStatus
    )

    Write-LogInfo 'Request all accounts with Azure AD roles'
    
    $allAdminRoles = Get-MsolRole | %{ $roleName = $_.Name; `
        Get-MsolRoleMember -RoleObjectId $_.ObjectId | Select DisplayName, EmailAddress, `
        @{Name = 'M365Role'; Expression = {$roleName}}}

    Write-LogInfo "$($allAdminRoles.Count) accounts.roles found"

    if($MsolUsersWithMFAStatus) {
        Write-LogInfo 'Joining AD roles table with users MFA Status table'
        $allAdminRoles = Join-Object -Left $allAdminRoles -Right $MsolUsersWithMFAStatus `
        -LeftJoinProperty 'EmailAddress' -RightJoinProperty 'UserPrincipalName'
        Write-Verbose "$($allAdminRoles.count) accounts.roles with MFA status found"
    }
    
    $exportFullPath = "$pwd\Audit\$ExportName\MsolAdminRoles-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $allAdminRoles | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $allAdminRoles
}

<#
.DESCRIPTION
    Export tenant password policy settings in CSV file
.NOTES
    MSOL PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-MsolPasswordPolicyCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-MsolPasswordPolicyCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all accounts with Azure AD roles'
    
    $passwordPolicies = Get-MsolDomain | % {
            Write-Verbose "Request $($_.Name) domains password policies";
            $CurrentName = $_.Name;
            Get-MsolPasswordPolicy -DomainName $_.Name 
        } | Select-Object `
        @{Label="Domain";Expression={$CurrentName}}, `
        @{Label="NotificationDays";Expression={$_.NotificationDays}}, `
        @{Label="ValidityPeriod";Expression={$_.ValidityPeriod}} 

    Write-LogInfo "$($passwordPolicies.Count) password policies found"
    
    $exportFullPath = "$pwd\Audit\$ExportName\MsolPasswordPolicy-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $passwordPolicies | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $passwordPolicies
}

<#
.DESCRIPTION
    Export all M365 servers names in a TXT file 
.NOTES
    MSOL PowerShell Module required
.PARAMETER ExportName
    Used in TXT export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-MsolM365ServersNamesTXTExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-MsolM365ServersNamesTXTExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request Microsoft server names used by M365 services'
    
    $serversNames = (Get-MsolCompanyInformation).AuthorizedServiceInstances

    Write-LogInfo "$($serversNames.Count) servers found"
    
    $exportFullPath = "$pwd\Audit\$ExportName\MsolM365ServersNames-$ExportName-$DateFileString.txt"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $serversNames > $exportFullPath 

    $serversNames
}

<#
.DESCRIPTION
    Export all M365 Company information in a TXT file 
.NOTES
    MSOL PowerShell Module required
.PARAMETER ExportName
    Used in TXT export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-MsolM365CompanyInfoTXTExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-MsolM365CompanyInfoTXTExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request tenant Company information'
    
    $companyInformation = Get-MsolCompanyInformation

    Write-LogInfo "$($companyInformation.Count) informations found"
    
    $exportFullPath = "$pwd\Audit\$ExportName\MsolM365CompanyInfo-$ExportName-$DateFileString.txt"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $companyInformation | select * > $exportFullPath 

    $companyInformation
}