<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.DefenderForO365.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 12/02/2021
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening Defender for Office365

    .DESCRIPTION
        Create Antiphishing Policy and Rule.
        Create SafeLinks Policy
        Create SafeAttachments Policy
#>


Function Start-DefenderO365P1AntiPhishingPolicy {
     <#
        .Synopsis
         create Antiphishing Policy and Rule.
        
        .Description
         This function will create new Antiphishing Policy

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$PolicyName = "Harden365 - AntiPhishing Policy",
    [String]$RuleName = "Harden365 - AntiPhishing Rule",
    [Boolean]$EnableFirstContactSafetyTips = $true,
    [Boolean]$EnableMailboxIntelligenceProtection = $true,
    [Boolean]$EnableMailboxIntelligence = $true,
    [String]$MailboxIntelligenceProtectionAction = "MoveToJmf",
    [Boolean]$EnableSimilarDomainsSafetyTips = $true,
    [Boolean]$EnableSimilarUsersSafetyTips = $true,
    [String]$TargetedUserProtectionAction = "Quarantine",
    [Boolean]$EnableTargetedUserProtection = $true,
    [Boolean]$EnableTargetedDomainsProtection = $true,
    [Boolean]$EnableOrganizationDomainsProtection = $true,
    [String]$TargetedDomainProtectionAction = "Quarantine",
    [Boolean]$EnableUnusualCharactersSafetyTips = $true,
    [String]$PhishThresholdLevel = "2",
	[String]$Priority = "0"
)

Write-LogSection 'MICROSOFT DEFENDER FOR OFFICE365' -NoHostOutput


#SCRIPT
    if ((Get-AntiPhishRule).name -ne $RuleName)
    {
        Try { 
            $WarningActionPreference = "SilentlyContinue"
            Set-AntiPhishPolicy -Identity "Office365 AntiPhish Default" -EnableMailboxIntelligenceProtection $EnableMailboxIntelligenceProtection -EnableMailboxIntelligence $EnableMailboxIntelligenceProtection -MailboxIntelligenceProtectionAction $MailboxIntelligenceProtectionAction -EnableFirstContactSafetyTips $EnableFirstContactSafetyTips -EnableSimilarDomainsSafetyTips $EnableSimilarDomainsSafetyTips -EnableSimilarUsersSafetyTips $EnableSimilarUsersSafetyTips -TargetedUserProtectionAction $TargetedUserProtectionAction -EnableTargetedUserProtection $EnableTargetedUserProtection -EnableTargetedDomainsProtection $EnableTargetedDomainsProtection -EnableOrganizationDomainsProtection $EnableOrganizationDomainsProtection -TargetedDomainProtectionAction $TargetedDomainProtectionAction -EnableUnusualCharactersSafetyTips $EnableUnusualCharactersSafetyTips -PhishThresholdLevel $PhishThresholdLevel
            New-AntiPhishPolicy -Name $PolicyName -AdminDisplayName $PolicyName -TargetedDomainsToProtect ((Get-AcceptedDomain).Name) -EnableMailboxIntelligenceProtection $EnableMailboxIntelligenceProtection -EnableFirstContactSafetyTips $EnableFirstContactSafetyTips -EnableMailboxIntelligence $EnableMailboxIntelligence -MailboxIntelligenceProtectionAction $MailboxIntelligenceProtectionAction -EnableSimilarDomainsSafetyTips $EnableSimilarDomainsSafetyTips -EnableSimilarUsersSafetyTips $EnableSimilarUsersSafetyTips -TargetedUserProtectionAction $TargetedUserProtectionAction -EnableTargetedUserProtection $EnableTargetedUserProtection -EnableTargetedDomainsProtection $EnableTargetedDomainsProtection -EnableOrganizationDomainsProtection $EnableOrganizationDomainsProtection -TargetedDomainProtectionAction $TargetedDomainProtectionAction -EnableUnusualCharactersSafetyTips $EnableUnusualCharactersSafetyTips -PhishThresholdLevel $PhishThresholdLevel
            New-AntiPhishRule -Name $RuleName -AntiPhishPolicy $PolicyName -Priority $Priority -RecipientDomainIs ((Get-AcceptedDomain).Name)
            Write-LogInfo "$PolicyName created"  
        } Catch {
                Write-LogError "$PolicyName not created!" }
    } else
    {
         Write-LogWarning "$PolicyName already created!" }

}

Function Start-DefenderO365P1SafeAttachments {
     <#
        .Synopsis
         create SafeAttachments Policy.
        
        .Description
         This function will active SafeAttachments Policy

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$PolicyName = "Harden365 - SafeAttachments Policy",
    [String]$RuleName = "Harden365 - SafeAttachments Rule",
    [String]$Alias = "AlertsMailbox",
    [Boolean]$Enable = $true,
    [String]$Action = "Block",
    [Boolean]$Redirect = $true,
    [Boolean]$EnableSafeDocs = $true,
    [Boolean]$EnableATPForSPOTeamsODB = $true,
    [Boolean]$AllowSafeDocsOpen = $false,
	[String]$Priority = "0"
)


#SCRIPT
$DomainOnM365=(Get-AcceptedDomain | Where-Object { $_.InitialDomain -match $true}).Name
    if ((Get-SafeAttachmentRule).name -ne $RuleName)
    {
        Try { 
            New-SafeAttachmentPolicy -Name $PolicyName -Enable $Enable -Action $Action -Redirect $Redirect -RedirectAddress "$Alias@$DomainOnM365"
            New-SafeAttachmentRule -Name $RuleName -SafeAttachmentPolicy $PolicyName -Priority $Priority -RecipientDomainIs ((Get-AcceptedDomain).Name)
            Set-AtpPolicyForO365 -EnableATPForSPOTeamsODB $EnableATPForSPOTeamsODB -EnableSafeDocs $EnableSafeDocs -AllowSafeDocsOpen $AllowSafeDocsOpen -WarningAction:SilentlyContinue
            Write-LogInfo "$PolicyName created"  
        } Catch {
                Write-LogError "$PolicyName not created!" }
    } else
    {
         Write-LogWarning "$PolicyName already created!" }
}

Function Start-DefenderO365P1SafeLinks {
     <#
        .Synopsis
         create SafeLinks Policy
        
        .Description
         This function will active SafeLinks Policy

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$PolicyName = "Harden365 - SafeLinks Policy",
    [String]$RuleName = "Harden365 - SafeLinks Rule",
    [Boolean]$IsEnabled = $true,
    [Boolean]$EnableSafeLinksForTeams = $true,
    [Boolean]$EnableSafeLinksForEmail = $true,
    [Boolean]$ScanUrls = $true,
    [Boolean]$DeliverMessageAfterScan = $true,
    [Boolean]$EnableForInternalSenders = $true,
    [Boolean]$AllowClickThrough = $false,
    [Boolean]$DoNotAllowClickThrough = $true,
    [String]$DoNotRewriteUrls = $UrlSafeLinksExcept,
    [Boolean]$TrackClicks = $true,
    [Boolean]$EnableSafeLinksForO365Clients = $true,
	[String]$Priority = "0"
)


#SCRIPT

    if ((Get-SafeLinksRule).name -ne $RuleName)
    {
        Try { 
            New-SafeLinksPolicy -Name $PolicyName -EnableSafeLinksForTeams $EnableSafeLinksForTeams -ScanUrls $ScanUrls -DeliverMessageAfterScan $DeliverMessageAfterScan -EnableForInternalSenders $EnableForInternalSenders -DoNotRewriteUrls $DoNotRewriteUrls -AllowClickThrough $AllowClickThrough -TrackClicks $TrackClicks
         if (-not (Get-SafeLinksPolicy -Identity $PolicyName).DoNotAllowClickThrough)
            {} else {  Set-SafeLinksPolicy -Identity $PolicyName  -DoNotAllowClickThrough $DoNotAllowClickThrough }
         if ($(Get-SafeLinksPolicy -Identity $PolicyName).EnableSafeLinksForEmail -eq $false)
            {Set-SafeLinksPolicy -Identity $PolicyName  -EnableSafeLinksForEmail $EnableSafeLinksForEmail } else {   }          
            New-SafeLinksRule -Name $RuleName -SafeLinksPolicy $PolicyName -Priority $Priority -RecipientDomainIs ((Get-AcceptedDomain).Name)
            Write-LogInfo "$PolicyName created"  
        } Catch {
                Write-LogError "$PolicyName not created!" }
    } else
    {
         Write-LogWarning "$PolicyName already created!" }

Write-LogSection '' -NoHostOutput
}
