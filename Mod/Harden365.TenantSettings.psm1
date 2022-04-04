<#
https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference

(Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | select ServiceType,ServiceName,TargetClass | Sort-Object ServiceType,ServiceName
MDE_SMB : ServiceType "WindowsDefenderATP"
EMS = ENTERPRISE MOBILITY + SECURITY E3
EMSPREMIUM = ENTERPRISE MOBILITY + SECURITY E5
EOP_ENTERPRISE = Exchange Online Protection
ADALLOM_STANDALONE = Microsoft Cloud App Security
WIN_DEF_ATP = MICROSOFT DEFENDER FOR ENDPOINT
ATA = Microsoft Defender for Identity
ADALLOM_O365 = Office 365 Cloud App Security
#>

Connect-MSOLService

## TENANT EDITION
if (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" }| Select -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "AAD_PREMIUM_P2")
    { $TenantEdition = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match "AAD_PREMIUM_P2" }).ServiceName
      Write-Host "Tenant Edition is Azure AD Premium Plan 2" }    
elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "AAD_PREMIUM")
    { $TenantEdition = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match "AAD_PREMIUM" }).ServiceName
      Write-Host "Tenant Edition is Azure AD Premium Plan 1" }
elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "AAD_BASIC")
    { $TenantEdition = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match "EOP_ENTERPRISE" }).ServiceName
      Write-Host "Tenant Edition is Azure AD Free" }

## MESSAGING SECURITY
if (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "THREAT_INTELLIGENCE")
    { $O365ATP = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match "THREAT_INTELLIGENCE" }).ServiceName
      Write-Host "Your messaging security is Defender for Office365 Plan 2" }    
elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "ATP_ENTERPRISE")
    { $O365ATP = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match "ATP_ENTERPRISE" }).ServiceName
      Write-Host "Your messaging security is Defender for Office365 Plan 1" }
elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "EOP_ENTERPRISE")
    { $O365ATP = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match "EOP_ENTERPRISE" }).ServiceName
      Write-Host "Your messaging security is Exchange Online Protection" }

