<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.Applications.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   05/12/2022
        Last Updated: 05/12/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Audit Applications Settings

    .DESCRIPTION
        Audit Outlook Application
        Audit Teams Application
        Audit PowerPlatform

#>

Function Start-OUTAudit {
     <#
        .Synopsis
         Audit Outlook Application
        
        .Description
         Audit Outlook Application

        .Notes
         Version: 01.00 -- 
         
    #>

Write-LogInfo "**** AUDIT APPLICATION OUTLOOK"

#LEGACY AUTHENTIFICATION
try {
if ($(Get-OrganizationConfig).OAuth2ClientProfileEnabled -eq $false) { 
    Write-LogWarning "Modern Auth in ExchangeOnline is disable!"
    }
else { Write-LogInfo "Modern Auth in ExchangeOnline enabled"}    
} catch{ Write-LogError "Module error" }
 

#EXTERNAL STORAGE PROVIDER
try {
if ($(Get-OwaMailboxPolicy).AdditionalStorageProvidersAvailable -eq $true) { 
    Write-LogWarning "External storage Provider is available in Outlook !"
    }
else { Write-LogInfo "External storage Provider is disabled"
}
} catch{ Write-LogError "Module error" }


#CALENDAR SHARING
try {
$calendars = Get-SharingPolicy | Where-Object { ($_.Domains -like '*CalendarSharing*') -and ($_.Enabled -eq $true) }
if (!$calendars) { Write-LogInfo 'No Policy with Calendar Sharing found' }
    else { ForEach ($calendar in $calendars) { 
    Write-LogWarning 'Policy with calendar sharing found' }
    }
} catch{ Write-LogError "Module error" }

#OUTLOOK ADD INS
try{
$OutAddins= (Get-EXOMailbox | Select-Object -Unique RoleAssignmentPolicy | ForEach-Object { 
    Get-RoleAssignmentPolicy -Identity $_.RoleAssignmentPolicy | Where-Object {
        ($_.AssignedRoles -like "*Apps*") -and ($_.IsDefault -eq $true)}} | Select-Object Identity, @{Name="AssignedRoles"; Expression={Get-Mailbox | Select-Object -Unique RoleAssignmentPolicy | ForEach-Object {
            Get-RoleAssignmentPolicy -Identity $_.RoleAssignmentPolicy | Select-Object -ExpandProperty AssignedRoles | Where-Object {$_ -like "*Apps*"}}}})

if (!$OutAddins) { 
    Write-LogInfo "Outlook AddIns disable for self activation"
    }
else { Write-LogWarning "Outlook AddIns is self activation enabled !"
}
} catch{ Write-LogError "Module error" }
Write-LogSection '' -NoHostOutput      
}

Function Start-OUTCheckAddIns {
     <#
        .Synopsis
         Check Outlook AddIns for each user
        
        .Description
         Check Outlook AddIns for each user

        .Notes
         Version: 01.00 -- 
         
    #>

Write-LogSection 'OUTLOOK' -NoHostOutput

#SCRIPT
mkdir -Force ".\Audit" | Out-Null
$dateFileString = Get-Date -Format "FileDateTimeUniversal"
    Get-Mailbox -ResultSize Unlimited | where-object {$_.RecipientTypeDetails -ne 'DiscoveryMailbox'} | ForEach-Object {
        (Get-App -Mailbox $_.PrimarySMTPAddress  | where-object {($_.Type -eq 'MarketPlace') -and ($_.Enabled -eq $true)} | Select-Object MailboxOwnerId,DisplayName,Appversion)
    } | Export-Csv -Path ".\Audit\AuditOutlookAddIns$dateFileString.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation 
Write-LogInfo "Audit Outlook AddIns generated in folder .\Audit"      
}

Function Start-TEAAudit {
     <#
        .Synopsis
         Audit Teams Application
        
        .Description
         Audit Teams Application

        .Notes
         Version: 01.00 -- 
         
    #>

Write-LogInfo "**** AUDIT APPLICATION TEAMS"


<#LEGACY AUTHENTIFICATION
if ($(Get-CsOAuthConfiguration).ClientAdalAuthOverride -eq "Disallowed") { 
    Write-LogWarning "Modern Auth in Teams is disable!"
    }
else { Write-LogInfo "Modern Auth in Teams enabled"}
#>

#PRESENTER-ROLE
if ((Get-CsTeamsMeetingPolicy -Identity Global).DesignatedPresenterRoleMode -ne 'OrganizerOnlyUserOverride') {
    Write-LogWarning "Meeting Presenter role setting not correct" 
    }
else { Write-LogInfo "Meeting Presenter role setting is correct"}    

#AUTOADMITTEDUSERS
if ((Get-CsTeamsMeetingPolicy -Identity Global).AutoAdmittedUsers -ne 'InvitedUsers') {
Write-LogWarning "AutoAdmitted setting is not correct" 
} 
else { Write-LogInfo "AutoAdmitted setting is correct"} 

#ANONYMOUSJOINMEETING
if ((Get-CsTeamsMeetingPolicy -Identity Global).AllowAnonymousUsersToJoinMeeting  -eq $true) {
Write-LogWarning 'Anonymous Users allowed to Join Meeting !' 
}
else { Write-LogInfo "Anonymous Users disallowed to Join Meeting"
}

#EXTERNAL CONTROL
if ((Get-CsTeamsMeetingPolicy -Identity Global).AllowExternalParticipantGiveRequestControl -ne $false) {
Write-LogWarning "AllowExternalParticipantGiveRequestControl enabled !" 
} else { Write-LogInfo "AllowExternalParticipantGiveRequestControl disabled"}
Write-LogSection '' -NoHostOutput   


#EXTERNAL STORAGE PROVIDER
try {
if ((Get-CsTeamsClientConfiguration).AllowDropBox -eq $true) { 
    Write-LogWarning "DropBox allowed in Teams !"
    }
    else {Write-LogInfo "DropBox disabled in Teams"}
if ((Get-CsTeamsClientConfiguration).AllowBox -eq $true) { 
    Write-LogWarning "Box allowed in Teams !"
    }
    else {Write-LogInfo "Box disabled in Teams"}
if ((Get-CsTeamsClientConfiguration).AllowGoogleDrive -eq $true) { 
    Write-LogWarning "GoogleDrive allowed in Teams !"
    }
    else {Write-LogInfo "GoogleDrive disabled in Teams"}
if ((Get-CsTeamsClientConfiguration).AllowShareFile -eq $true) { 
    Write-LogWarning "ShareFile allowed in Teams !"
    }
    else {Write-LogInfo "ShareFile disabled in Teams"}
if ((Get-CsTeamsClientConfiguration).AllowEgnyte -eq $true) { 
    Write-LogWarning "Egnyte allowed in Teams !"
    }
    else {Write-LogInfo "Egnyte disabled in Teams"}
}catch{}
Write-LogSection '' -NoHostOutput
}

Function Start-POWAudit {
     <#
        .Synopsis
         Audit PowerPlatform Application
        
        .Description
         Audit PowerPlatform Application

        .Notes
         Version: 01.00 -- 
         
    #>

    Param(
        [System.Management.Automation.PSCredential]$Credential
        #$password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))
    )

Write-LogInfo "**** AUDIT APPLICATION POWERPLATFORM"


#BLOCKFREESUBSCRIPTION
try {
if ((Get-MsolCompanyInformation).AllowAdHocSubscriptions -eq $true) {
    Write-LogWarning "Standard users enabled to creating free subscriptions"}
else {Write-LogInfo "Standard users already disabled to create free subscriptions"}
} catch{ Write-LogError "Module error BLOCKFREESUBSCRIPTION" }

<#SHAREEVERYONE
try {
Add-PowerAppsAccount -Username $Credential.UserName -Password $Credential.Password
if ((Get-TenantSettings).powerPlatform.powerApps.disableShareWithEveryone -eq $false) {
    Write-LogWarning "User allow to share apps with everyone"}
else {Write-LogInfo "Standard users already disabled to share apps with everyone"}
} catch{ Write-LogError "Module error" }

#BLOCKTRIALSUBSCRIPTION
try {
Add-PowerAppsAccount -Username $Credential.UserName -Password $Credential.Password
if (((Get-AllowedConsentPlans).Types -eq "Internal") -or ((Get-AllowedConsentPlans).Types -eq "Viral")) {
    Write-LogWarning "Prevent standard users from creating trial/developer subscriptions"}
else {Write-LogInfo "Standard users already disabled to create trial/developer subscriptions"}
} catch{ Write-LogError "Module error" }
#>

#BLOCKPAYABLESUBSCRIPTION
Connect-MSCommerce
$Products = Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase
ForEach ($Product in $Products) {
        $productName = $Product.ProductName
    if ($Product.PolicyValue -eq "Enabled") {
        Write-LogWarning "Prevent standard users from creating $ProductName payable subscriptions"}
    else {Write-LogInfo "Standard users already disabled to subscribe $ProductName payable subscriptions"}
    }
# catch{ Write-LogError "Module error BLOCKPAYABLESUBSCRIPTION" }
Write-LogSection '' -NoHostOutput
}

