<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.Identity.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   27/04/2022
        Last Updated: 27/04/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Audit Identity Section CIS

    .DESCRIPTION
        ModernAuthSetting
        TenantEdition.
        Defender ATP
        Create SafeAttachments Policy
#>

Connect-ExchangeOnline
Connect-MicrosoftTeams

$NameM365 = $((Get-AzureADDomain | Where-Object { $_.Name -match 'onmicrosoft.com'}).Name) -split '.onmicrosoft.com'
$URL = $NameM365+"admin.sharepoint.com"



Connect-SPOService -Url https://fernandezfrance-admin.sharepoint.com

Function Start-ModernAuthSetting {
     <#
        .Synopsis
         Check Modern Authentification.
        
        .Description
         This function will check and set Modern Authentication.

        .Notes
         Version: 01.00 -- 
         
    #>



Write-LogSection 'MODERN AUTHENTIFICATION' -NoHostOutput



#EXCHANGE
if ($(Get-OrganizationConfig).OAuth2ClientProfileEnabled -eq $false) { 
    Write-LogWarning "Modern Auth in ExchangeOnline is disable!"
    Set-OrganizationConfig -OAuth2ClientProfileEnabled $true
    Write-LogInfo "Modern Auth in ExchangeOnline set to enable"
    }
else { Write-LogInfo "Modern Auth in ExchangeOnline enabled"}

#TEAMS
if ($(Get-CsOAuthConfiguration).ClientAdalAuthOverride -eq "Disallowed") { 
    Write-LogWarning "Modern Auth in Teams is disable!"
    Set-CsOAuthConfiguration -ClientAdalAuthOverride Allowed
    Write-LogInfo "Modern Auth in Teams set to enable"
    }
else { Write-LogInfo "Modern Auth in Teams enabled"}

#SHAREPOINT
if ($(Get-SPOTenant).LegacyAuthProtocolsEnabled -eq $true) { 
    Write-LogWarning "Modern Auth in SharepointOnline is disable!"
    Set-SPOTenant -LegacyAuthProtocolsEnabled $false
    Write-LogInfo "Modern Auth in Teams set to enable"
    }
else { Write-LogInfo "Modern Auth in SharepointOnline enabled"}

 Write-LogSection '' -NoHostOutput

}

