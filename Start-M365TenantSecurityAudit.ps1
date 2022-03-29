<#
.DESCRIPTION
    Run a whole asecurity udit of a M365 tenant. All data are exported at CSV/TXT format.
    Run with an account with Global Reader + SharePoint admin permissions.
    Verbose option supported
.NOTES
    File Name      : Start-M365TenantSecurityAudit.ps1
    Author         : Sébastien Paulet (SPT Conseil)
    Prerequisite   : PowerShell V5.1, Exchange Online PowerShell Module, MSOnline PowerShell Module and Azure AD PowerShell Module 
.PARAMETER CompanyName
    Used in CSV export name (use company/tenant name)
.EXAMPLE
    .\Start-M365TenantSecurityAudit.ps1 -CompanyName "Contoso" -verbose
#>
param(
    [Parameter(Mandatory = $true)]
	[String]$CompanyName,
    [switch]$reloadModules
)

$totalCountofOperations = 35
$currentCountOfOperations = 0

clear-Host
(0..10)| % {write-host }

if ($reloadModules) {
    Remove-Module 'Harden365.debug' > $null
    Remove-Module 'Harden365.prerequisites' > $null
}

Write-Host("LOADING HARDEN 365") -ForegroundColor Red
Import-Module '.\config\Harden365.debug.psm1'
$dateFileString = Get-Date -Format 'FileDateTimeUniversal'
$debugFileFullPath = "$pwd\Logs\Debug$dateFileString.log"
New-Item -Path $debugFileFullPath -ItemType File > $null

Import-Module '.\config\Harden365.prerequisites.psm1'
Add-AuditFolder -ExportName $CompanyName
if ($reloadModules) {
    Remove-AllHarden365Modules
}

## PREREQUISITES
Test-AllPrerequisites -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$currentCountOfOperations++

Import-AllScriptModules -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$currentCountOfOperations++

## CONNECION TO M365 SERVICES
Connect-AllM365Services -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$currentCountOfOperations++

mkdir -Force "$pwd\$CompanyName\" > $null

## REQUESTS TO AZURE AD
Update-ProgressionBarOuterLoop -Activity 'Export DNS records' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$dnsRecordsList = Get-AzureADDNSRecordsCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export all AD Users' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$azureADUsersList = Get-AzureADUsersCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export all AD Service Plans' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$azureADSKUsList = Get-AzureADPlanCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export Plans per user' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$azureADUserLicences = Get-AzureADUsersLicencesCSVExport -ExportName  $CompanyName -DateFileString $dateFileString -AllUsers $azureADUsersList -LicensePlanList $azureADSKUsList
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export users sign ins logs' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$userSignIns = Get-UsersSignInCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export all Azure AD Groups' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$azureADGroups = Get-AzureADGroupsCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

## REQUESTS TO EXO
Update-ProgressionBarOuterLoop -Activity 'Export Audit settings' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$adminAuditLogConfig = Get-ExoAdminAuditLogConfigTXTExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export EXO mailboxes information' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoMailBoxes = Get-ExoAllMailboxesCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export EXO mailboxes statistics (long operation)' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoMailBoxesStatistics = Get-ExoAllMailboxesStatisticsCSVExport -ExportName $CompanyName -DateFileString $dateFileString -ExoMailBoxes $exoMailBoxes
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export EXO mailboxes CAS information' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoMailBoxesCAS = Get-ExoAllCASMailboxesCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export EXO mailboxes auto forward rules' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoMailBoxesAutoForward = Get-ExoAllMailboxesForwardRulesCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export EXO transport rules' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoTransportRules = Get-ExoTransportRulesCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export EXO Sensitivity labels' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoSensitivityLabels = Get-ExoAllSensitivityLabelsCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export EXO Sensitivity labels policies' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoSensitivityLabelsPolicies = Get-ExoAllSensitivityLabelPoliciesCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export EXO authentication policies' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoSensitivityLabelsPolicies = Get-ExoAuthenticationPoliciesCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export EXO organization settings' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoOrganizationSetting = Get-ExoOrgaConfigTXTExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export Add-MailboxPermission events' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoAddMailBoxPermissionEvents = Get-ExoAddMailBoxPermissionEventsCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export SiteCollectionAdminAdded events' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoSiteCollectionAdminAddedEvents = Get-ExoSiteCollectionAdminAddedEventsCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export all Hosted Content Filter Rules' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoHostedContentFilterRules = Get-ExoHostedContentFilterRulesCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export all Hosted Content Filter Policies' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoHostedContentFilterPolicies = Get-ExoHostedContentFilterPoliciesCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export all Hosted Outbound Spam Filter Rules' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoHostedOutboundSpamFilterRules = Get-ExoHostedOutboundSpamFilterRulesCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export all Hosted Outbound Spam Filter Policies' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoHostedOutboundSpamFilterPolicies = Get-ExoHostedOutboundSpamFilterPoliciesCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export allMalware Filter Rules' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoMalwareFilterRules = Get-ExoMalwareFilterRulesCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export all Malware Filter Policies' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$exoMalwareFilterPolicies = Get-ExoMalwareFilterPoliciesCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

## REQUESTS TO MSOL
Update-ProgressionBarOuterLoop -Activity 'Export Company Informations' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$companyInformation = Get-MsolM365CompanyInfoTXTExport -ExportName $CompanyName -DateFileString $dateFileString 
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export accounts and MFA status' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$msolUsersWithMFAStatus = Get-MsolUsersMFAStatusCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export accounts with admin roles' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$allAdminRoles = Get-MsolAdminRolesCSVExport -ExportName $CompanyName -DateFileString $dateFileString -MsolUsersWithMFAStatus $msolUsersWithMFAStatus
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export password policies' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$passwordPolicies = Get-MsolPasswordPolicyCSVExport -ExportName $CompanyName -DateFileString $dateFileString
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export Microsoft server names used by M365 services' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$serversNames = Get-MsolM365ServersNamesTXTExport -ExportName $CompanyName -DateFileString $dateFileString 
$currentCountOfOperations++

## REQUESTS TO SPO
Update-ProgressionBarOuterLoop -Activity 'Export all SharePoint site collections' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$allSPOSites = Get-SPOSitesCollectionCSVExport -ExportName $CompanyName -DateFileString $dateFileString 
$currentCountOfOperations++

Update-ProgressionBarOuterLoop -Activity 'Export all OneDrive site collections' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$allO4BSites = Get-SPOOneDrivesCSVExport -ExportName $CompanyName -DateFileString $dateFileString 
$currentCountOfOperations++

## ORCA
Update-ProgressionBarOuterLoop -Activity 'Launch ORCA tool' -Status 'In progress'  -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
Invoke-ORCA -Output @("HTML","JSON") -OutputDirectory ".\Audit\$CompanyName\" > $null
$currentCountOfOperations++