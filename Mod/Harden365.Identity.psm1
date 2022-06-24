





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



