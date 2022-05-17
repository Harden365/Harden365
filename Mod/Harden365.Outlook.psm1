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

MSO
EOP

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


Function Start-OUTBlockOutlookAddIns {
     <#
        .Synopsis
         Create policy to block Outlook AddIns install by user
        
        .Description
         Create policy to block Outlook AddIns install by user

        .Notes
         Version: 01.00 -- 
         
    #>



#SCRIPT
$newPolicyName = "Role Assignment Policy - Prevent Add-ins"
$revisedRoles = <#"MyTeamMailboxes", "MyTextMessaging",#> "MyDistributionGroups", "MyMailSubscriptions", "MyBaseOptions", "MyVoiceMail", "MyProfileInformation", "MyContactInformation", "MyRetentionPolicies", "MyDistributionGroupMembership"
New-RoleAssignmentPolicy -Name $newPolicyName -Roles $revisedRoles
Set-RoleAssignmentPolicy -id $newPolicyName -IsDefault Get-Mailbox -ResultSize Unlimited | Set-Mailbox -RoleAssignmentPolicy $newPolicyName
Write-LogInfo "Policy $newPolicyName created"      
}


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
Get-SharingPolicy | Where-Object { ($_.Domains -like '*CalendarSharing*') -and ($_.Enabled -eq $true) } | ForEach-Object { Set-SharingPolicy -Identity $_.Name -Enabled $false 
Write-LogInfo 'Policy share details calendar disabled' }
} catch { Write-LogInfo 'Policy already disabled' }
Write-LogSection '' -NoHostOutput        
}

