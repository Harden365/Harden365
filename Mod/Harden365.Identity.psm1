$NameM365 = $((Get-AzureADDomain | Where-Object { $_.Name -match 'onmicrosoft.com'}).Name) -split '.onmicrosoft.com'
$URL = $NameM365+"admin.sharepoint.com"



Connect-SPOService -Url https://fernandezfrance-admin.sharepoint.com
#SHAREPOINT
if ($(Get-SPOTenant).LegacyAuthProtocolsEnabled -eq $true) { 
    Write-LogWarning "Modern Auth in SharepointOnline is disable!"
    Set-SPOTenant -LegacyAuthProtocolsEnabled $false
    Write-LogInfo "Modern Auth in Teams set to enable"
    }
else { Write-LogInfo "Modern Auth in SharepointOnline enabled"}





Function Start-UserConsentToApp {
     <#
        .Synopsis
         Disable User permission consent App registration
        
        .Description
         Disable User permission consent App registration

        .Notes
         Version: 01.00 -- 
         
    #>

#SCRIPT
if ((Get-MsolCompanyInformation).UsersPermissionToUserConsentToAppEnabled  -eq $true) {
Set-MsolCompanySettings -UsersPermissionToUserConsentToAppEnabled $false
Write-LogInfo 'Disable User permission consent App registration' 
}
      
}



