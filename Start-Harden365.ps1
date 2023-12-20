<# 
    .NOTES
    ===========================================================================
        FileName:     harden365.ps1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 11/29/2021
        Version:      v0.7
    ===========================================================================

    .DESCRIPTION
        Protect your data in minutes

    .DEPENDENCIES
        PowerShell 5.1
        Security Default disable

    .UPDATES
    0.8 - 01/15/2023
        Rewrite debug system
    0.7 - 11/27/2021
        Rewrite debug system
    0.6 - 11/26/2021
        Rewrite prerequisites
    0.5 - 11/02/2021
        Add notes
    0.4 - 09/28/2021
        Add Menu


#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$reloadModules
)

$totalCountofOperations = 2
$currentCountOfOperations = 0

clear-Host
(0..10)| ForEach-Object {write-host }

if ($reloadModules) {
    Remove-Module 'Harden365.debug'
    Remove-Module 'Harden365.prerequisites'
}

## INTERFACE
write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
Write-Host("LOADING HARDEN 365") -ForegroundColor Red
Import-Module '.\config\Harden365.debug.psm1'
Import-Module '.\config\Harden365.prerequisites.psm1'
Import-Module '.\config\Harden365.Menu.psm1'
if ($reloadModules) {
    Remove-AllHarden365Modules
}

## PREREQUISITES
Test-AllPrerequisites -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$currentCountOfOperaions++
Import-AllScriptModules -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$currentCountOfOperations++

## CREDENTIALS
write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
Write-Host("PLEASE CONNECT TO GRAPH WITH GLOBAL ADMINISTRATOR") -ForegroundColor Yellow
start-sleep -Seconds 1
Connect-MgGraph -ContextScope Process -Scopes Directory.Read.All,RoleManagement.ReadWrite.Directory,User.ReadWrite.All,Group.ReadWrite.All,Application.Readwrite.All,UserAuthenticationMethod.ReadWrite.All,Policy.Read.All,Policy.ReadWrite.ConditionalAccess,AuditLog.Read.All,UserAuthenticationMethod.Read.All,PrivilegedAccess.ReadWrite.AzureADGroup,PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup | Out-Null

try { Get-MgDomain }
catch {
    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
    Write-Host("AUTHENTIFICATION FAILED") -ForegroundColor red
    Read-Host -Prompt "Press Enter to quit_"
    Exit-PSSession
    }

#GRAPH
#TENANT NAME
$TenantName = (Get-MgDomain | Where-Object { $_.IsDefault -eq $true }).Id
#AZUREADEDITION
if (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "AAD_PREMIUM_P2")
{ $TenantEdition = "Azure AD Premium P2"} 
elseif (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "AAD_PREMIUM")
{ $TenantEdition = "Azure AD Premium P1"} 
elseif (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "AAD_BASIC")
{ $TenantEdition = "Azure AD Basic"} 
else
{ $TenantEdition = "Azure AD Free" }
#OFFICE365ATP
if (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "THREAT_INTELLIGENCE")
    { $O365ATP = "Defender for Office365 P2" }   
elseif (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "ATP_ENTERPRISE")
    { $O365ATP = "Defender for Office365 P1" }  
elseif (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "EOP_ENTERPRISE")
    { $O365ATP = "Exchange Online Protection" }  
else
{ $TenantEdition = "Azure AD Free" }


## RUN MAIN MENU
MainMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP

