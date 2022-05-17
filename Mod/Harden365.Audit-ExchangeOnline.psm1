<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.Audit-ExchangeOnline.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   05/11/2022
        Last Updated: 05/11/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Audit Exchange Online Protection

    .DESCRIPTION
        check autoforwarding
        check Mailbox permissions
        check Calendar permissions
        check Contacts permissions

#>


Function Start-EOPCheckAutoForward {
     <#
        .Synopsis
         check autoforwarding
        
        .Description
         This function will check autoforwarding

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
)

#SCRIPT

            $dateFileString = Get-Date -Format 'FileDateTimeUniversal'
            $debugFolderPath = Join-Path $pwd 'Audit'
            if (!(Test-Path -Path $debugFolderPath)) {
              New-Item -Path $pwd -Name 'Audit' -ItemType Directory > $null
            }
            $debugFileFullPath = Join-Path $debugFolderPath "CheckAutoforward$dateFileString.log"
            "$(Get-Date -UFormat "%m-%d-%Y %T ") **** AUTOFORWARDING" | Out-File "$debugFileFullPath" -Append

            # Check autoforwarding in transport rule
            Write-Loginfo "Check autoforwarding in transport rule"
            #$AutoforwardTP = @()
            Get-TransportRule | Where-Object {$null -ne $_.RedirectMessageTo} | ForEach-Object {
            if ($_ -ne $null) {
            "$(Get-Date -UFormat "%m-%d-%Y %T ") - Autoforwarding found in rule $($_.Name)  to $($_.RedirectMessageTo)" | Out-File "$debugFileFullPath" -Append
            Write-LogWarning "Autoforwarding found in rule $($_.Name)  to $($_.RedirectMessageTo)"
            }
            }

            # Check autoforwarding in exchange admin mailbox setting
            Write-LogInfo "Check autoforwarding in mailbox settings"
            ((Get-Mailbox -ResultSize Unlimited) | Where-Object { ($null -ne $_.ForwardingAddress) -or ($null -ne $_.ForwardingsmtpAddress)}) | ForEach-Object {
            if ($_ -ne $null) {
            "$(Get-Date -UFormat '%m-%d-%Y %T ') - Autoforwarding found in $($_.UserPrincipalName)  to $($_.ForwardingAddress -split "SMTP:") $($_.ForwardingSmtpAddress -split "SMTP:")" | Out-File "$debugFileFullPath" -Append
            Write-LogWarning "Autoforwarding found in $($_.UserPrincipalName)  to $($_.ForwardingAddress -split "SMTP:") $($_.ForwardingSmtpAddress -split "SMTP:")"
            }
            }
                                    
            # Check autoforwarding in all inbox rule
            Write-LogInfo "Check autoforwarding in inbox rules"
            $rules=Get-Mailbox -ResultSize Unlimited| ForEach-Object {
            Get-InboxRule -Mailbox $PSItem.primarysmtpaddress -WarningAction:SilentlyContinue | Where-Object {$_.Enabled -eq $true}}
            $forwardingRules = $rules | Where-Object {($null -ne $_.forwardto) -or ($null -ne $_.forwardsattachmentto) -or ($null -ne $_.Redirectto)}
            foreach ($rule in $forwardingRules) {
            "$(Get-Date -UFormat "%m-%d-%Y %T ") - Mailbox '$($rule.MailboxOwnerId)' forward to '$($rule.ForwardTo)$($rule.RedirectTo)'" | Out-File "$debugFileFullPath" -Append
            Write-LogWarning "Mailbox '$($rule.MailboxOwnerId)' forward to '$($rule.ForwardTo)$($rule.RedirectTo)'"
            }
            
}


Function Start-EOPCheckPermissionsMailbox {
     <#
        .Synopsis
         check Mailbox permissions
        
        .Description
         This function will check Mailbox permissions

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
)

#SCRIPT
$MailboxCollection = @()
$MailboxCollection = Get-Mailbox -ResultSize Unlimited

$Permissions = @()
$Permissions = Get-Mailbox -ResultSize Unlimited | where-object {$_.RecipientTypeDetails -ne 'DiscoveryMailbox'} | ForEach-Object { Get-MailboxPermission -Identity $_.UserPrincipalName | where-object {$_.User -ne 'NT AUTHORITY\SELF'} | select-object Identity,AccessRights,User}

foreach ($item in $Permissions) {
    foreach ($obj in $item) {
        $obj | Add-Member -MemberType NoteProperty -Name 'Type' -Value ($MailboxCollection | Where-Object { $_.Name -eq $obj.Identity }).RecipientTypeDetails
        $obj | Add-Member -MemberType NoteProperty -Name 'Name' -Value ($MailboxCollection | Where-Object { $_.Name -eq $obj.Identity }).Name
        $obj | Add-Member -MemberType NoteProperty -Name 'UserPrincipalName' -Value ($MailboxCollection | Where-Object { $_.Name -eq $obj.Identity }).UserPrincipalName
        }
        }



# Export CSV
Write-Loginfo "Check permissions in all mailbox"
$dateFileString = Get-Date -Format "FileDateTimeUniversal"
mkdir -Force ".\Audit" | Out-Null
$Permissions | Select-Object Name,UserprincipalName,Type,AccessRights,User | Export-Csv -Path ".\Audit\AuditMailboxPermission$dateFileString.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation
   
}


Function Start-EOPCheckPermissionsCalendar {
     <#
        .Synopsis
         check Calendar permissions
        
        .Description
         This function will check Calendar permissions

        .Notes
         Version: 01.00 --  
         
    #>

	param(
)

#SCRIPT
$CalendarPermissions=Get-Mailbox -ResultSize Unlimited | where-object {$_.RecipientTypeDetails -ne 'DiscoveryMailbox'} | ForEach-Object {
        Get-MailboxFolderPermission -Identity "$($_.PrimarySMTPAddress):\Calendrier"  -WarningAction:SilentlyContinue | Where-Object {$_.User.DisplayName -ne "Par Défaut" -and $_.User.DisplayName -ne "Anonyme"}
        Write-LogInfo " Check calendar permission for $_"
        }

# Export CSV
Write-Loginfo "Check permissions in all Calendars"
$dateFileString = Get-Date -Format "FileDateTimeUniversal"
mkdir -Force ".\Audit" | Out-Null
$CalendarPermissions | Select-Object Identity,User,AccessRights | Export-Csv -Path ".\Audit\AuditCalendarPermission$dateFileString.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation
   
}


Function Start-EOPCheckPermissionsContacts {
     <#
        .Synopsis
         check Contacts permissions
        
        .Description
         This function will check Contacts permissions

        .Notes
         Version: 01.00 --  
         
    #>

	param(
)

#SCRIPT
$ContactPermissions=Get-Mailbox -ResultSize Unlimited | where-object {$_.RecipientTypeDetails -ne 'DiscoveryMailbox'} | ForEach-Object {
        Get-MailboxFolderPermission -Identity "$($_.PrimarySMTPAddress):\Contacts"  -WarningAction:SilentlyContinue | Where-Object {$_.User.DisplayName -ne "Par Défaut" -and $_.User.DisplayName -ne "Anonyme"}
        Write-LogInfo " Check contacts permission for $_"
        }

# Export CSV
Write-Loginfo "Check permissions in all Contacts"
$dateFileString = Get-Date -Format "FileDateTimeUniversal"
mkdir -Force ".\Audit" | Out-Null
$ContactPermissions | Select-Object Identity,User,AccessRights | Export-Csv -Path ".\Audit\AuditContactPermission$dateFileString.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation
   
}