<#
.SYNOPSIS
    Export all usefull information related to Azure AD users listed in a CSV file to a CSV file in a subfolder in current folder
.DESCRIPTION
    Azure AD PowerShell Module required,
    Exchange ONline PowerShell Module required,
    MSOnline PowerShell Module required,
    Verbose option supported
.NOTES
    ===========================================================================
        FileName:     harden365.ps1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 11/29/2021
        Version:      v0.7
    ===========================================================================
.PARAMETER CompanyName
    Used in CSV export name (use company/tenant name), and, if CheckAccountsOutOfCompany switch is used, check that AD Company name begin witgh this string
.PARAMETER AccountCSVListPath
    Path of the UTF-8 encoded CSV file containing the whole list of users to follow in a "UserPrincipalName" column. It can be left empty
.PARAMETER CheckAccountsWithoutDirectMFA
    If used, script will import all users on which there is no direct MFA enabled
.PARAMETER CheckAccountsOutOfCompany
    If used, will load all accounts on which AD field "Company Name" doen't begin with script "CompanyName" parameter
.PARAMETER CheckAccountsWithADPriviledges
    Path of the UTF-8 encoded CSV file containing the whole list of users to follow in a "UserPrincipalName" column. It can be empty
.EXAMPLE
    .\Get-AADAccountFollowUp.ps1 -CompanyName "Contoso" -AccountCSVListPath ".\Contoso-KnownADAccountsToFollow.csv" -CheckAccountsWithoutDirectMFA -CheckAccountsOutOfCompany -CheckAccountsWithADPriviledges -verbose
#>

param(
    [Parameter(Mandatory = $true)]
	[String]$CompanyName = "Contoso",
    [String]$AccountCSVListPath
)

Write-Verbose 'Connecting to various M365 services'

$isAADConnectedBefore = $false
try {
    Get-AzureADSubscribedSku | Out-Null 
    Write-Verbose 'Open Azure AD connexion found'
    $isAADConnectedBefore = $true
} catch {} 
if (-not $isAADConnectedBefore) {
    Write-Verbose 'Connecting to Azure AD'
    Connect-AzureAD
}

if (Get-MsolCompanyInformation -ErrorAction SilentlyContinue ) {
    Write-Verbose 'Open Msol connexion detected'
}else {
    Write-Verbose 'Connecting Msol'
    Connect-MsolService
}

$isEXOConnectedBefore = $false
try { 
    Get-EXOMailbox -Filter "UserPrincipalName  -eq '9'" -errorAction SilentlyContinue -Verbose:$false
    Write-Verbose 'Open EXO connexion detected'
    $isEXOConnectedBefore = $true
} catch {}
if (-not $isEXOConnectedBefore) {    
    Write-Verbose 'Connecting EXO'
    Connect-ExchangeOnline -ShowBanner:$false
}

$dateFileString = Get-Date -Format "FileDateTimeUniversal"

mkdir -Force "$pwd\Audit\$CompanyName\" | Out-Null 

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
        text-align:left;
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

if ($AccountCSVListPath) {
    Write-Verbose 'Load CSV users'
    $usersToFollowUPN = Import-Csv  -Delimiter ';' -Path $AccountCSVListPath -Encoding UTF8 | % { 
        $_.UserPrincipalName 
    }
    Write-Verbose "$($usersToFollowUPN.Count) users found in CSV $AccountCSVListPath"
} else {
    Write-Verbose 'No CSV list of users'
}

Write-Verbose 'Load all accounts with AD priviledges'
$allAdminRoles = Get-MsolRole | %{ $roleName = $_.Name; `
    Get-MsolRoleMember -RoleObjectId $_.ObjectId | select EmailAddress, @{Name = 'M365Role'; Expression = {$roleName}}}
Write-Verbose "$($allAdminRoles.Count) admin roles found"
$usersToFollowUPN += $allAdminRoles | % {$_.EmailAddress}

$usersToFollowUPN = $usersToFollowUPN | Select -unique
Write-Verbose "$($usersToFollowUPN.Count) user to followUp"

Write-Verbose 'Load Azure suscribed SKUs'
$licensePlanList = Get-AzureADSubscribedSku

$userFollowUpExportData = $usersToFollowUPN | % {
    [PSCustomObject]@{
        UserPrincipalName = $_
        DisplayName = ''
        ShowInAddressList = ''
        CompanyName = ''
        Country = ''
        Manager=''
        UserType = ''
        AccountEnabled = ''
        Licences = ''
        WhenCreated = ''
        LastPasswordChangeTimestamp = ''
        IsLicensed = ''
        BlockCredential = ''
        MFAStatus = ''
        MFAMethod = ''
        StrongPasswordRequired = ''
        StrongAuthenticationProofupTime = ''
        EXOLitigationHoldEnabled = ''
        EXORecipientTypeDetails = ''
        EXOPopEnabled = ''
        EXOImapEnabled = ''
        EXOSmtpClientAuthenticationDisabled = ''
        EXOItemCount = ''
        EXOTotalItemSize = ''
        EXOLastInteractionTime = ''
        M365Roles = ''
        LastConnexions = ''
    } 
}

$userFollowUpExportData | % {
    $currentUserFollowUpExportData = $_

    Write-Verbose "Load $($currentUserFollowUpExportData.UserPrincipalName) AAD infos"

    try {
        $currentUserAADInfo = Get-AzureADUser -ObjectId $_.UserPrincipalName -errorAction SilentlyContinue
    } catch { }

    if ($currentUserAADInfo -eq $null) {
        Write-Warning "$($currentUserFollowUpExportData.UserPrincipalName) user not found in AAD"
        $currentUserFollowUpExportData.DisplayName = "User not found"
    } else {
        $currentUserFollowUpExportData.UserType = $currentUserAADInfo.UserType
        $currentUserFollowUpExportData.DisplayName = $currentUserAADInfo.DisplayName
        $currentUserFollowUpExportData.CompanyName = $currentUserAADInfo.CompanyName
        $currentUserFollowUpExportData.Country = $currentUserAADInfo.Country
        $currentUserFollowUpExportData.AccountEnabled = $currentUserAADInfo.AccountEnabled
        
        $currentUserAADInfo.AssignedLicenses | % { 
            $currentSkuID = $_.SkuId; 
            $licensePlanList | % { 
                If ( $currentSkuID -eq $_.ObjectId.substring($_.ObjectId.length - 36, 36) ) { 
                   $currentUserFollowUpExportData.Licences += "$($_.SkuPartNumber), "
                }
            }
        }

        $currentUserFollowUpExportData.Manager = Get-AzureADUserManager -ObjectId $_.UserPrincipalName | % {$_.UserPrincipalName}
    
        Write-Verbose "Load $($currentUserFollowUpExportData.UserPrincipalName) Msol infos"
        $currentUserMsolInfo = Get-MsolUser -UserPrincipalName $_.UserPrincipalName -errorAction SilentlyContinue

        if ($currentUserMsolInfo -eq $null) {
            Write-Warning "$($currentUserFollowUpExportData.UserPrincipalName) user not found in Msol"
        } else {
            $currentUserFollowUpExportData.WhenCreated = $currentUserMsolInfo.WhenCreated
            $currentUserFollowUpExportData.LastPasswordChangeTimestamp = $currentUserMsolInfo.LastPasswordChangeTimestamp
            $currentUserFollowUpExportData.IsLicensed = $currentUserMsolInfo.IsLicensed
            $currentUserFollowUpExportData.BlockCredential = $currentUserMsolInfo.BlockCredential
            $currentUserFollowUpExportData.MFAStatus = if( $currentUserMsolInfo.StrongAuthenticationRequirements.State -ne $null) { $currentUserMsolInfo.StrongAuthenticationRequirements.State } else { "Disabled"}
            if( $currentUserMsolInfo.StrongAuthenticationMethods.MethodType -ne $null) { $currentUserMsolInfo.StrongAuthenticationMethods.MethodType | % {$currentUserFollowUpExportData.MFAMethod += "$($_), "}}
            $currentUserFollowUpExportData.StrongPasswordRequired = $currentUserMsolInfo.StrongPasswordRequired
            $currentUserFollowUpExportData.StrongAuthenticationProofupTime = $currentUserMsolInfo.StrongAuthenticationProofupTime
        }

        Write-Verbose "Load $($currentUserFollowUpExportData.UserPrincipalName) EXO infos"

        $currentUserEXOlInfo = Get-EXOMailbox -Identity $_.UserPrincipalName -ErrorAction SilentlyContinue -Verbose:$false

        if ($currentUserEXOlInfo -eq $null) {
            Write-Warning "$($currentUserFollowUpExportData.UserPrincipalName) user not found in EXO"
            $currentUserFollowUpExportData.EXORecipientTypeDetails = "No mailbox found"
        } else {
            $currentUserFollowUpExportData.ShowInAddressList = $currentUserEXOlInfo.ShowInAddressList
            $currentUserFollowUpExportData.EXOLitigationHoldEnabled = $currentUserEXOlInfo.LitigationHoldEnabled
            $currentUserFollowUpExportData.EXORecipientTypeDetails = $currentUserEXOlInfo.RecipientTypeDetails
            
            $currentUserEXOlCASInfo = Get-EXOCasMailbox -Identity $currentUserEXOlInfo.PrimarySmtpAddress -Verbose:$false
            $currentUserFollowUpExportData.EXOPopEnabled = $currentUserEXOlCASInfo.PopEnabled
            $currentUserFollowUpExportData.EXOImapEnabled = $currentUserEXOlCASInfo.ImapEnabled
            $currentUserFollowUpExportData.EXOSmtpClientAuthenticationDisabled = $currentUserEXOlCASInfo.SmtpClientAuthenticationDisabled

            $currentUserEXOlStatisticsInfo = Get-ExoMailboxStatistics -Identity $currentUserEXOlInfo.PrimarySmtpAddress -Verbose:$false
            $currentUserFollowUpExportData.EXOItemCount = $currentUserEXOlStatisticsInfo.ItemCount
            $currentUserFollowUpExportData.EXOTotalItemSize = $currentUserEXOlStatisticsInfo.TotalItemSize
            $currentUserFollowUpExportData.EXOLastInteractionTime = $currentUserEXOlStatisticsInfo.LastInteractionTime
        }

        Write-Verbose "Get $($currentUserFollowUpExportData.UserPrincipalName) Admin roles"
        $allAdminRoles | ? {$currentUserFollowUpExportData.UserPrincipalName -eq $_.EmailAddress} | % { $currentUserFollowUpExportData.M365Roles += "$($_.M365Role), "}

        
        Write-Verbose "Get $($currentUserFollowUpExportData.UserPrincipalName) connexion logs"
        $connexionlogs = Get-AzureADAuditSignInLogs -Filter "UserPrincipalName eq '$($currentUserFollowUpExportData.UserPrincipalName)'" -Top 3 | select UserPrincipalName, CreatedDateTime, Status, Location, MfaDetail
        $connexionlogs | % { $currentUserFollowUpExportData.LastConnexions += "$($_.CreatedDateTime);$($_.Location.CountryOrRegion)-$($_.Location.State);$($_.ClientAppUsed)-$($_.MfaDetail.AuthMethod);$($_.Status.ErrorCode)-$($_.Status.FailureReason)`n"}
    }
}

$userFollowUpExportData | Export-Csv -Path "$pwd\Audit\$CompanyName\AADUsersFollowUp-$CompanyName-$dateFileString.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation
$userFollowUpExportData | ConvertTo-Html `
-Property "UserPrincipalName","DisplayName","ShowInAddressList","CompanyName","Country","Manager","UserType","AccountEnabled","Licences","WhenCreated","LastPasswordChangeTimestamp","IsLicensed","BlockCredential","MFAStatus","MFAMethod","StrongPasswordRequired","StrongAuthenticationProofupTime","EXOLitigationHoldEnabled","EXORecipientTypeDetails","EXOPopEnabled","EXOImapEnabled","EXOSmtpClientAuthenticationDisabled","EXOItemCount","EXOTotalItemSize","EXOLastInteractionTime","M365Roles","LastConnexions" `
 -PreContent "<h1>Azure AD Follow Up</h1>" "<h2>$DomainOnM365</h2>" -Head $Header -Title "Harden 365 - Audit" -PostContent "<h2>$(Get-Date -UFormat "%d-%m-%Y %T ")</h2>"`
> "$pwd\Audit\$CompanyName\AADUsersFollowUp-$CompanyName-$dateFileString.html"
Invoke-Expression ".\Audit\$CompanyName\AADUsersFollowUp-$CompanyName-$dateFileString.html"