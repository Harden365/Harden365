<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.Outlook.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   05/12/2022
        Last Updated: 05/12/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening Outlook Environnement

    .DESCRIPTION
        Check Outlook AddIns for each user
        Create policy to block Outlook AddIns install by user
        Enable OAuth in ExchangeOnline
        Confirm Modern Auth activation
        Block file sharing for other cloud storage services
        Prevent share details calendar


#>


Function Start-OUTAuthActivation {
     <#
        .Synopsis
         Enable OAuth in ExchangeOnline
        
        .Description
         Enable OAuth in ExchangeOnline

        .Notes
         Version: 01.00 -- 
         
    #>

Write-LogSection 'HARDENING OUTLOOK' -NoHostOutput

#SCRIPT
if ($(Get-OrganizationConfig).OAuth2ClientProfileEnabled -eq $false) { 
    Write-LogWarning "Modern Auth in ExchangeOnline is disable!"
    Set-OrganizationConfig -OAuth2ClientProfileEnabled $true
    Write-LogInfo "Modern Auth in ExchangeOnline set to enable"
    }
else { Write-LogInfo "Modern Auth in ExchangeOnline enabled"}    
}

<#
Function Start-OUTBlockOutlookAddIns {
     <#
        .Synopsis
         Create policy to block Outlook AddIns install by user
        
        .Description
         Create policy to block Outlook AddIns install by user

        .Notes
         Version: 01.00 -- 
         
    #

	param(
	[Parameter(Mandatory = $false)]
	[String]$PolicyName = "Harden365 - Prevent Add-ins"
    )

#OUTLOOK ADD INS
try{
$OutAddins= (Get-EXOMailbox | Select-Object -Unique RoleAssignmentPolicy | ForEach-Object { 
    Get-RoleAssignmentPolicy -Identity $_.RoleAssignmentPolicy | Where-Object {
        ($_.AssignedRoles -like "*Apps*") -and ($_.IsDefault -eq $true)}} | Select-Object Identity, @{Name="AssignedRoles"; Expression={Get-Mailbox | Select-Object -Unique RoleAssignmentPolicy | ForEach-Object {
            Get-RoleAssignmentPolicy -Identity $_.RoleAssignmentPolicy | Select-Object -ExpandProperty AssignedRoles | Where-Object {$_ -like "*Apps*"}}}})

if (!$OutAddins) { 
    Write-LogInfo "Outlook AddIns disable for self activation"
    }
else { 
    Write-LogWarning "Outlook AddIns is self activation enabled !"
    New-RoleAssignmentPolicy -Name $PolicyName -Roles $OutAddins
    Set-RoleAssignmentPolicy -Identity $PolicyName -IsDefault -Confirm:$false
    Get-Mailbox -ResultSize Unlimited | Set-Mailbox -RoleAssignmentPolicy $PolicyName
    Write-LogInfo "Policy $PolicyName created"      
}
} catch{ Write-LogError "Module error" }
}
#>

Function Start-OUTBlockStorageTiers {
     <#
        .Synopsis
         Block External storage providers available in Outlook on the Web
        
        .Description
         Block External storage providers available in Outlook on the Web

        .Notes
         Version: 01.00 -- 
         
    #>



#SCRIPT
if ($(Get-OwaMailboxPolicy).AdditionalStorageProvidersAvailable -eq $true) { 
    Write-LogWarning "External stagorage Provider is available in Outlook !"
    Set-OwaMailboxPolicy -Identity OwaMailboxPolicy-Default -AdditionalStorageProvidersAvailable $false
    Write-LogInfo "External storage Provider is disabled"
    }
else { Write-LogInfo "External storage Provider is disabled"
}
Write-LogSection '' -NoHostOutput    
}


Function Start-OUTCalendarSharing {
     <#
        .Synopsis
         Prevent share details calendar
        
        .Description
         Prevent share details calendar

        .Notes
         Version: 01.00 -- 
         
    #>

#SCRIPT
try {
if (Get-SharingPolicy | Where-Object { ($_.Domains -like '*CalendarSharing*') -and ($_.Enabled -eq $true) }) { 
    Get-SharingPolicy | Where-Object { ($_.Domains -like '*CalendarSharing*') -and ($_.Enabled -eq $true) } |
    ForEach-Object {
    Write-LogWarning 'Policy with calendar sharing found'
    Set-SharingPolicy -Identity $_.Name -Enabled $false
    Write-LogInfo 'Policy with Calendar Sharing disabled' }
    }
    else { Write-LogInfo 'Policy with Calendar Sharing not found' }
} catch{ Write-LogError "Module error" }
Write-LogSection '' -NoHostOutput        
}

