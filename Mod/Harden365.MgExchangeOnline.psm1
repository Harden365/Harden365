<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.ExchangeOnline.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 12/02/2021
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening Exchange Online Protection

    .DESCRIPTION
        Create SharedMailbox for alerts
        Create group for autoforward excluded
        Create group for Antispam strict policy
        Create Antispam Strict Policy and Rule
        Create Antispam Standard Policy and Rule
        Create Antimalware Policy and Rule
        Create transport rules to warm user for Office files with macro
        Create transport rules to block AutoForwarding mail out Organization
        Enable Unified Audit Log
#>

Function Start-EOPAlertsMailbox {
     <#
        .Synopsis
         create shared mailbox for alerts
        
        .Description
         This function will create shared mailbox for alerts 
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Alerts Mailbox2",
    [String]$Alias = "AlertsMailbox"
)

Write-LogSection 'EXCHANGE ONLINE PROTECTION' -NoHostOutput

#SCRIPT
$DomainOnM365=((Get-MgOrganization).VerifiedDomains | Where-Object { $_.IsInitial -match $true}).Name



            
            #DMARC Config
            $Domains=((Get-MgOrganization).VerifiedDomains | Where-Object { $_.Name -notmatch "onmicrosoft.com"}).Name

}

Function Start-EOPAutoForwardGroup {
     <#
        .Synopsis
         Create group for autoforward excluded
        
        .Description
         This function will create new group for Autoforward excluded
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - GP AutoForward Exclude",
    [String]$Alias = "gp_autoforward_exclude2",
    [String]$Members = ""
)


#SCRIPT
$DomainOnM365=((Get-MgOrganization).VerifiedDomains | Where-Object { $_.IsInitial -match $true}).Name
$GroupEOL=(Get-DistributionGroup | Where-Object { $_.DisplayName -eq $Name}).Name

    if (-not $GroupEOL)
        {
        Try {
            New-DistributionGroup -Name $Name -Type "Security" -PrimarySmtpAddress $Alias@$DomainOnM365 | Set-DistributionGroup -HiddenFromAddressListsEnabled $true
            New-MgGroup -DisplayName $Name -MailEnabled:$true -ProxyAddresses SMTP:$Alias@$DomainOnM365 -MailNickName '$alias' -SecurityEnabled $true -HideFromAddressLists:$true
            New-MgGroup -DisplayName $Name -MailEnabled:$fase -MailNickName '$alias' -SecurityEnabled
            Write-LogInfo "Group '$Name' created"
            }
                 Catch {
                        Write-LogError "Group '$Name' not created"
                        }
    }
    else { 
         Write-LogWarning "Group '$Name' already created!"
         }
}

Get-MgGroup -GroupId 7622c42d-e20f-4a37-8a7e-7027a15304d7 | fl
New-MgGroup -DisplayName 'Test Group' -MailEnabled:$False  -MailNickName 'testgroup' -SecurityEnabled
