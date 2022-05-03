<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.TenantSettings.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   05/04/2022
        Last Updated: 05/04/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Get tenant information

    .DESCRIPTION
        TenantInfos
        TenantEdition
        Defender ATP
        HashSyncPassword
        SSPR
#>
Function Check-TenantInfos {
     <#
        .Synopsis
         Check Tenant Azure AD Edition plan.
        
        .Description
         Check Tenant Azure AD Edition plan.

        .Notes
         Version: 01.00 -- 
         
    #>

#SCRIPT
$TenantDisplayName = (Get-MsolCompanyInformation).DisplayName
$TenantPrimaryDomain = (Get-MsolDomain | Where-Object { $_.IsDefault -eq $true }).Name
$TenantDirectorySync = (Get-MsolCompanyInformation).DirectorySynchronizationEnabled
}

Function Check-TenantEdition {
     <#
        .Synopsis
         Check Tenant Azure AD Edition plan.
        
        .Description
         Check Tenant Azure AD Edition plan.

        .Notes
         Version: 01.00 -- 
         
    #>

#SCRIPT
if (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" }| Select -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "AAD_PREMIUM_P2")
    { $TenantEdition = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match "AAD_PREMIUM_P2" }).ServiceName
      $TenantEdition = "Azure AD Premium P2" }    
elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "AAD_PREMIUM")
    { $TenantEdition = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match "AAD_PREMIUM" }).ServiceName
       $TenantEdition = "Azure AD Premium P1" }  
elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "AAD_BASIC")
    { $TenantEdition = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match "EOP_ENTERPRISE" }).ServiceName
      $TenantEdition = "Azure AD Free" }  
}

Function Check-DefenderATP {
     <#
        .Synopsis
         Check Defender ATP plan.
        
        .Description
         Check Defender ATP plan.

        .Notes
         Version: 01.00 -- 
         
    #>

#SCRIPT
if (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "THREAT_INTELLIGENCE")
    { $O365ATP = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match "THREAT_INTELLIGENCE" }).ServiceName
      $TenantEdition = "Defender for Office365 P2" }   
elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "ATP_ENTERPRISE")
    { $O365ATP = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match "ATP_ENTERPRISE" }).ServiceName
      $TenantEdition = "Defender for Office365 P1" }  
elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match "EOP_ENTERPRISE")
    { $O365ATP = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne "0" } | Select -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match "EOP_ENTERPRISE" }).ServiceName
      $TenantEdition = "Exchange Online Protection" }  
}

Function Check-HashSyncPassword {
     <#
        .Synopsis
         Check Hash Sync Password
        
        .Description
         Check Hash Sync Password

        .Notes
         Version: 01.00 -- 
         
    #>

#SCRIPT
if ($(Get-MsolCompanyInformation).DirectorySynchronizationEnabled -eq $true) {
if ($(Get-MsolCompanyInformation).PasswordSynchronizationEnabled -eq $false){ 
    Write-LogWarning "Hash Sync Password not enabled!"
    $HashSync = $false
    }
else {
      Write-LogInfo "Hash Sync Password enabled"
      $HashSync = $true
      }
}
}

Function Check-SSPR {
     <#
        .Synopsis
         Check SSPR
        
        .Description
         Check SSPR

        .Notes
         Version: 01.00 -- 
         
    #>

#SCRIPT
if ($(Get-MsolCompanyInformation).SelfServePasswordResetEnabled -eq $false) { 
    Write-LogWarning "SSPR not enabled!"
    $SSPR = $false
    }
else {
      Write-LogInfo "SSPR enabled"
      $SSPR = $true
      }
}

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

Security Default : (Get-OrganizationConfig).isDehydrated

#>