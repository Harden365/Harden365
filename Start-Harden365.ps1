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
$currentCountOfOperations++
Import-AllScriptModules -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$currentCountOfOperations++

## CREDENTIALS
write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
Write-Host("PLEASE CONNECT ACCOUNT WITH GLOBAL ADMINISTRATOR/READER ROLE WITHOUT MFA CONTROL") -ForegroundColor Yellow
start-sleep -Seconds 1
$ErrorActionPreference = "SilentlyContinue"
$Credential = Get-Credential -Message "Global Administrator/Reader without MFA Control"
if ($null -eq $Credential){
Write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-Host("ACTION STOPPED BY USER") -ForegroundColor Red
Pause;Break}
try {
Connect-AzureAD -Credential $Credential | Out-Null
Get-AzureADTenantDetail | Out-Null 
} catch {
Write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-Host("USER/PASSWORD NOT VALID OR MFA ACTIVED") -ForegroundColor Red
Pause;Break} 

#TENANT DETAIL
Connect-MsolService -Credential $Credential | Out-Null
#TENANT NAME
$TenantName = (Get-MsolDomain | Where-Object { $_.IsDefault -eq $true }).Name
#AZUREADEDITION
if (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" }| Select-Object -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "AAD_PREMIUM_P2")
{ $TenantEdition = "Azure AD Premium P2"} 
elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select-Object -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "AAD_PREMIUM")
{ $TenantEdition = "Azure AD Premium P1"} 
elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select-Object -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "AAD_BASIC")
{ $TenantEdition = "Azure AD Basic"} 
#OFFICE365ATP
if (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select-Object -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "THREAT_INTELLIGENCE")
    { $O365ATP = "Defender for Office365 P2" }   
elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select-Object -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "ATP_ENTERPRISE")
    { $O365ATP = "Defender for Office365 P1" }  
elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select-Object -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "EOP_ENTERPRISE")
    { $O365ATP = "Exchange Online Protection" }  


## RUN MAIN MENU
MainMenu -Credential $Credential -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP

