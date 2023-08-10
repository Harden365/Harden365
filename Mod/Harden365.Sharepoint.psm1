<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.AuditSharepoint.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   05/18/2022
        Last Updated: 05/18/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Get Sharepoint information

    .DESCRIPTION
        TenantInfos
        TenantEdition
        Defender ATP
        HashSyncPassword
        SSPR
#>



Function Start-LegacyAuthSPO {
     <#
        .Synopsis
         Disable User permission consent App registration
        
        .Description
         Disable User permission consent App registration

        .Notes
         Version: 01.00 -- 
         
    #>

Write-LogSection 'HARDENING SHAREPOINT' -NoHostOutput

#SCRIPT

if ($(Get-SPOTenant).LegacyAuthProtocolsEnabled -eq $true) { 
    Write-LogWarning "Legacy Auth in SharepointOnline is enable!"
    Set-SPOTenant -LegacyAuthProtocolsEnabled $false
    Write-LogInfo "legacy Auth in Sharepoint set to disable"
    }
else { Write-LogInfo "Legacy Auth in SharepointOnline disabled"}


}