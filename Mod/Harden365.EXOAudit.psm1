<#
.DESCRIPTION
    All audit function requesting Exchange Online
.NOTES
    Author:       Community Harden - contact@harden365.net
    Created On:   09/28/2021
    Last Updated: 11/26/2021
    Version:      v0.5
#>

<#
.DESCRIPTION
    Export all Exchange Audit log config in a TXT file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoAuthenticationPoliciesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoAdminAuditLogConfigTXTExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request tenant Audit settings'
    
    $adminAuditLogConfig = Get-AdminAuditLogConfig
    Write-LogInfo "Audit settings found"
    
    $exportFullPath = "$pwd\Audit\$ExportName\AdminAuditLogConfig-$ExportName-$DateFileString.txt"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $adminAuditLogConfig | select * > $exportFullPath
    
    $adminAuditLogConfig
}

<#
.DESCRIPTION
    Export all Exchange Mailboxes CAS infos in a CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoAllCASMailboxesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoAllCASMailboxesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all EXO mailboxes CAS informations'

    $exoMailBoxesCAS = Get-ExoCASMailbox -ResultSize unlimited 
    Write-LogInfo "$($exoMailBoxesCAS.Count) CAS mailboxes found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoAllCASMailboxes-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoMailBoxesCAS | select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoMailBoxesCAS
}

<#
.DESCRIPTION
    Export all Exchange Mailboxes infos in a CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoAllMailboxesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoAllMailboxesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all EXO mailboxes informations'

    $exoMailBoxes = Get-ExoMailbox -ResultSize unlimited 
    Write-LogInfo "$($exoMailBoxesCAS.Count) mailboxes found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoAllMailboxes-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoMailBoxes | select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoMailBoxes
}

<#
.DESCRIPTION
    Export all Exchange Mailboxes Statistics infos in a CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoAllMailboxesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoAllMailboxesStatisticsCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString,
        [Parameter(Mandatory = $true)]
        $ExoMailBoxes
    )

    Write-LogInfo 'Request all EXO mailboxes statistics informations'

    $exoMailBoxesStatistics = $ExoMailBoxes | % {Get-Mailboxstatistics -Identity $_.PrimarySmtpAddress }  
    Write-LogInfo "$($exoMailBoxesStatistics.Count) mailboxes found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoAllMailboxesStatistics-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoMailBoxesStatistics | Select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoMailBoxesStatistics
}

<#
.DESCRIPTION
    Export all Exchange Mailboxes which have auto forwarding rules infos in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoAllMailboxesForwardRulesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoAllMailboxesForwardRulesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all EXO mailboxes informations having forwarding rules'

    $exoMailBoxesAutoForward = Get-Mailbox -ResultSize Unlimited -Filter {(RecipientTypeDetails -ne "DiscoveryMailbox") `
                                        -and ((ForwardingSmtpAddress -ne $null) -or (ForwardingAddress -ne $null))} `
                                        | select UserPrincipalName, RecipientTypeDetails, ForwardingSmtpAddress, ForwardingAddress 
    Write-LogInfo "$($exoMailBoxesAutoForward.Count) mailboxes with forward rules found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoAllMailboxesForwardRules-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoMailBoxesAutoForward | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoMailBoxesAutoForward
}

<#
.DESCRIPTION
    Export all Exchange email transport rules in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoTransportRulesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoTransportRulesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all EXO email transport rules'

    $exoTransportRules = Get-TransportRule | Select Name, State, Mode, Priority, Comments, Description, IsValid, `
                                                        WhenChanged, Guid
    Write-LogInfo "$($exoTransportRules.Count) transport rules found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoTransportRules-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoTransportRules | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoTransportRules
}   

<#
.DESCRIPTION
    Export all existing sensitivity labels informations in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoAllSensitivityLabelsCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoAllSensitivityLabelsCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all EXO sensitivity labels set up'

    $exoSensitivityLabels = Get-Label
    Write-LogInfo "$($exoSensitivityLabels.Count) sensitivity labels found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoAllSensitivityLabels-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoSensitivityLabels | select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoSensitivityLabels
}   

<#
.DESCRIPTION
    Export all existing sensitivity labels policies informations in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoAllSensitivityLabelPoliciesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoAllSensitivityLabelPoliciesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all EXO sensitivity labels policies'

    $exoSensitivityLabelsPolicies = Get-LabelPolicy
    Write-LogInfo "$($exoSensitivityLabelsPolicies.Count) sensitivity label policies found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoAllSensitivityLabelPolicies-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoSensitivityLabelsPolicies | select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoSensitivityLabelsPolicies
} 

<#
.DESCRIPTION
    Export all Exchange authentication policies infos in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoAuthenticationPoliciesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoAuthenticationPoliciesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all EXO authentication policies'

    $exoAuthenticationPolicies = Get-AuthenticationPolicy
    Write-LogInfo "$($exoAuthenticationPolicies.Count) authentication policies found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoAuthenticationPolicies-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoAuthenticationPolicies | select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoAuthenticationPolicies
} 

<#
.DESCRIPTION
    Export all Exchange Organization Settings s in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoOrgaConfigTXTExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoOrgaConfigTXTExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all EXO organiszation settings'

    $exoOrganizationSetting = Get-OrganizationConfig
    Write-LogInfo "$($exoOrganizationSetting.Count) settings found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoOrgaConfig-$ExportName-$DateFileString.txt"
    Write-LogInfo "Export to TXT at $exportFullPath"
    $exoOrganizationSetting | select * > $exportFullPath

    $exoOrganizationSetting
} 

<#
.DESCRIPTION
    Export all Exchange domain settings in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoRemoteDomainsCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoRemoteDomainsCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all EXO domain settings'

    $exoRemoteDomains = Get-RemoteDomain
    Write-LogInfo "$($exoRemoteDomains.Count) authentication policies found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoRemoteDomains-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoRemoteDomains | select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoRemoteDomains
}

<#
.DESCRIPTION
    Export Add-MailboxPermission events list which occured during last 3 months in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoAddMailBoxPermissionEventsCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoAddMailBoxPermissionEventsCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all Add-MailboxPermission events'

    $exoAddMailBoxPermissionEvents = Search-AdminAuditLog -Cmdlets Add-MailboxPermission -StartDate (Get-Date).AddMonths(-3) -EndDate (Get-Date) -ExternalAccess $false | % {
        [PSCustomObject]@{
            ObjectModified = $_.ObjectModified
            Identity = $_.CmdletParameters | ? {$_.Name -eq 'Identity'} | % {$_.Value}
            User =  $_.CmdletParameters | ? {$_.Name -eq 'User'} | % {$_.Value}
            AccessRights =  $_.CmdletParameters | ? {$_.Name -eq 'AccessRights'} | % {$_.Value}
            InheritanceType =  $_.CmdletParameters | ? {$_.Name -eq 'InheritanceType'} | % {$_.Value}
            Caller = $_.Caller
            Succeeded = $_.Succeeded
            RunDate = $_.RunDate
            ClientIP = $_.ClientIP
            SessionId = $_.SessionId
            IsValid = $_.IsValid
        } 
    }
    Write-LogInfo "$($exoAddMailBoxPermissionEvents.Count) Add-MailboxPermission events found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoAddMailBoxPermissionEvents-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoAddMailBoxPermissionEvents | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoAddMailBoxPermissionEvents
}

<#
.DESCRIPTION
    Export SiteCollectionAdminAdded events list which occured during last 3 months
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoSiteCollectionAdminAddedEventsCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoSiteCollectionAdminAddedEventsCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all SiteCollectionAdminAdded events in logs'

    $exoSiteCollectionAdminAddedEvents = Search-UnifiedAuditLog -Operations SiteCollectionAdminAdded -StartDate (Get-Date).AddMonths(-3) -EndDate (Get-Date) | % {
        $convertedAuditData = convertfrom-json $_.AuditData
        [PSCustomObject]@{
            RecordType = $_.RecordType
            CreationDate = $_.CreationDate
            UserIds = $_.UserIds
            UserKey = $convertedAuditData.UserKey
            UserType = $convertedAuditData.UserType
            Workload = $convertedAuditData.Workload
            ClientIP = $convertedAuditData.ClientIP
            ObjectId = $convertedAuditData.ObjectId
            UserId = $convertedAuditData.UserId
            EventSource = $convertedAuditData.EventSource
            ItemType = $convertedAuditData.ItemType
            Site = $convertedAuditData.Site
            WebId = $convertedAuditData.WebId
            ModifiedProperties = $convertedAuditData.ModifiedProperties
            TargetUserOrGroupType = $convertedAuditData.TargetUserOrGroupType
            SiteUrl = $convertedAuditData.SiteUrl
            TargetUserOrGroupName = $convertedAuditData.TargetUserOrGroupName
            IsValid = $_.IsValid

        } 
    } 
    Write-LogInfo "$($exoSiteCollectionAdminAddedEvents.Count) SiteCollectionAdminAdded events found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoSiteCollectionAdminAddedEvents-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoSiteCollectionAdminAddedEvents | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoSiteCollectionAdminAddedEvents
}

<#
.DESCRIPTION
    Export Hosted Content Filter Rules in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoHostedContentFilterRulesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoHostedContentFilterRulesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all Hosted Content Filter Rules'

    $exoHostedContentFilterRules = Get-HostedContentFilterRule
    Write-LogInfo "$($exoHostedContentFilterRules.Count) Hosted Content Filter Rules found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoHostedContentFilterRules-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoHostedContentFilterRules | select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoHostedContentFilterRules
}

<#
.DESCRIPTION
    Export Hosted Content Filter Policies in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoHostedContentFilterPoliciesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoHostedContentFilterPoliciesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all Hosted Content Filter Policies'

    $exoHostedContentFilterPolicies = Get-HostedContentFilterPolicy
    Write-LogInfo "$($exoHostedContentFilterRules.Count) Hosted Content Filter Policies found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoHostedContentFilterPolicies-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoHostedContentFilterPolicies | select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoHostedContentFilterPolicies
}

<#
.DESCRIPTION
    Export Hosted Outbound Spam Filter Rules in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoHostedOutboundSpamFilterRulesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoHostedOutboundSpamFilterRulesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all Hosted Outbound Spam Filter Rules'

    $exoHostedOutboundSpamFilterRules = Get-HostedOutboundSpamFilterRule
    Write-LogInfo "$($exoHostedOutboundSpamFilterRules.Count) Hosted Outbound Spam Filter Rules found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoHostedOutboundSpamFilterRules-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoHostedOutboundSpamFilterRules | select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoHostedOutboundSpamFilterRules
}

<#
.DESCRIPTION
    Export Hosted Outbound Spam Filter Policies in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoHostedOutboundSpamFilterPoliciesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoHostedOutboundSpamFilterPoliciesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all Hosted Outbound Spam Filter Policies'

    $exoHostedOutboundSpamFilterPolicies = Get-HostedOutboundSpamFilterPolicy
    Write-LogInfo "$($exoHostedOutboundSpamFilterPolicies.Count) Hosted Outbound Spam Filter Policies found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoHostedOutboundSpamFilterRules-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoHostedOutboundSpamFilterPolicies | select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoHostedOutboundSpamFilterPolicies
}

<#
.DESCRIPTION
    Export Malware Filter Rules in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoMalwareFilterRulesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoMalwareFilterRulesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all Malware Filter Rules'

    $exoMalwareFilterRules = Get-MalwareFilterRule
    Write-LogInfo "$($exoMalwareFilterRules.Count) Hosted Malware Filter Rules found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoMalwareFilterRules-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoMalwareFilterRules | select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoMalwareFilterRules
}

<#
.DESCRIPTION
    Export Malware Filter Policies in CSV file
.NOTES
    Exchange Online PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-ExoMalwareFilterPoliciesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-ExoMalwareFilterPoliciesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all Malware Filter Policies'

    $exoMalwareFilterPolicies = Get-MalwareFilterPolicy
    Write-LogInfo "$($exoMalwareFilterPolicies.Count) Hosted Malware Filter Policies found"

    $exportFullPath = "$pwd\Audit\$ExportName\ExoMalwareFilterPolicies-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $exoMalwareFilterPolicies | select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $exoMalwareFilterPolicies
}