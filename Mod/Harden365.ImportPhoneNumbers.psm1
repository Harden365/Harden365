<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.ImportPhoneNumbers.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 01/19/2021
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening Import PhoneNumbers to activate MFA

    .DESCRIPTION
        Import csv for activate MFA by SMS.
#>


Function Start-ImportPhoneNumbers
{
     <#
        .Synopsis
         Import csv for activate MFA by SMS..
        
        .Description
         This function will import phone number for activate MFA by SMS token.

        .Sources
         https://docs.microsoft.com/en-us/azure/active-directory/authentication/howto-mfa-userdevicesettings
         https://janbakker.tech/prepopulate-phone-methods-for-mfa-and-sspr-using-graph-api/

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Import PhoneNumber",
    [String]$ImportCSV = "ImportPhoneNumbers.csv"
)

Write-LogSection 'IMPORT PHONE NUMBERS' -NoHostOutput

# Module Graph Identity
if($(Get-Command "Get-MgUserAuthenticationPhoneMethod" -ErrorAction:SilentlyContinue).Version -eq $null){

Write-LogInfo "Installing Powershell Module Graph Identity"
Install-module Microsoft.Graph.Identity.Signins -ErrorAction:SilentlyContinue -Scope CurrentUser -Confirm
Start-Sleep -Seconds 1
}
else{
Write-LogInfo "Loading Powershell Module Graph Identity"
Start-Sleep -Seconds 1
}

# Connect MgGraph
Write-LogInfo "Connect to Module Graph Identity"
Connect-MgGraph -Scopes UserAuthenticationMethod.ReadWrite.All
Select-MgProfile -Name beta


#SCRIPT
Write-LogInfo "Import CSV File : $ImportCSV"

Try {
     Import-CSV ".\Input\$ImportCSV" -Delimiter ";" | ForEach-Object {
     if($_.ImportPhoneNumber -eq "YES")
     {
     New-MgUserAuthenticationPhoneMethod -UserId $($_.UserPrincipalName) -phoneType "mobile" -phoneNumber $($_.PhoneNumbers) | Out-Null
     Write-LogInfo "$($_.UserPrincipalName) : PhoneNumber $($_.PhoneNumbers) added"
     }
     else { 
     Write-LogWarning "$($_.UserPrincipalName) : MFA not activated !"
     }
     }
     } catch { Write-LogError "Import CSV error" }

Disconnect-MgGraph -ErrorAction SilentlyContinue

Write-LogSection '' -NoHostOutput

}










