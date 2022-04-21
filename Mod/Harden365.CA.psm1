<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.CA.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 01/18/2021
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening Conditional Access

    .DESCRIPTION
        Create CA for admins connection
        Create group for exclude users
        Create CA for users connection
        Create group for legacy authentification
        Create CA for legacy authentification
#>



Function Start-GroupMFAUsersExclude {
     <#
        .Synopsis
         Create group to exclude users.
        
        .Description
         This function will create new group to exclude MFA.

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - CA Exclusion - MFA Users Exclude",
    [String]$mailNickName = "H365-MFAExclude"
)

Write-LogSection 'CONDITIONAL ACCESS' -NoHostOutput

#SCRIPT
$GroupAAD=Get-AzureADGroup -Filter "DisplayName eq '$Name'"
    if (-not $GroupAAD)
        {
        Try {
            New-AzureADGroup -Description "$Name" -DisplayName "$Name" -MailEnabled $false -SecurityEnabled $true -MailNickName $MailNickName
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

Function Start-LegacyAuthGroupExclude {
     <#
        .Synopsis
         Create group to legacy authentification.
        
        .Description
         This function will create new group to exclude LegacyAuth .

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - CA Exclusion - Legacy Authentification Exclude",
    [String]$mailNickName = "H365-LegacyExclude"
)


#SCRIPT
$GroupAAD=Get-AzureADGroup -Filter "DisplayName eq '$Name'"
    if (-not $GroupAAD)
        {
        Try {
            New-AzureADGroup -Description "$Name" -DisplayName "$Name" -MailEnabled $false -SecurityEnabled $true -MailNickName $MailNickName
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

Function Start-LegacyAuthPolicy {
     <#
        .Synopsis
         Create CA to legacy authentification.
        
        .Description
         This function will create Conditional Access Block for Legacy auth.

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Block Legacy Authentification",
	[String]$GroupExclude = "Harden365 - CA Exclusion - Legacy Authentification Exclude"
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name
    if (-not $CondAccPol){
        Try {
            $Conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $Conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $Conditions.Applications.IncludeApplications = "All"
            $Conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $Conditions.Users.IncludeUsers = "All"
            $Conditions.Users.ExcludeGroups = $ExcludeCAGroup
            $Conditions.ClientAppTypes = @('ExchangeActiveSync', 'Other')
            $Controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $Controls._Operator = "OR"
            $Controls.BuiltInControls = "Block"
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created"
                  }
 }

Function Start-MFAAdmins {
     <#
        .Synopsis
         Create CA to admins connection.
        
        .Description
         This function will create Conditionnal Access MFA for Admin roles .

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - MFA Admins"
)


#SCRIPT
$CARoles = @(
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Global Administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Application Administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Authentication Administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Billing Administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Cloud Application Administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Conditional Access Administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Exchange Administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Helpdesk administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Password administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Privileged authentication administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Privileged Role Administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Security administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "SharePoint administrator"}).ObjectId,
(Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "User administrator"}).ObjectId)

$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name

    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeRoles = $CARoles
            $conditions.Users.ExcludeRoles = (Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Directory Synchronization Accounts"}).ObjectId
            $conditions.Users.ExcludeUsers = (Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'").ObjectId
            $conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
            $controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $controls._Operator = "OR"
            $controls.BuiltInControls = @('MFA')
            $sessions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessSessionControls
            $sessions.SignInFrequency = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessSignInFrequency
            $sessions.SignInFrequency.Value = "9"
            $sessions.SignInFrequency.Type = "Hours"
            $sessions.SignInFrequency.IsEnabled = "true"
            $sessions.PersistentBrowser = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPersistentBrowser
            $sessions.PersistentBrowser.Mode = "Never"
            $sessions.PersistentBrowser.IsEnabled = "true"
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls -SessionControls $sessions
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
}

Function Start-MFAUsers {
     <#
        .Synopsis
         Create CA to users connection.
        
        .Description
         This function will create Conditional Access MFA for Users.
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - MFA Users",
	[String]$GroupExclude = "Harden365 - CA Exclusion - MFA Users Exclude"   
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name

    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Applications.ExcludeApplications = (Get-AzureADServicePrincipal -Filter "DisplayName eq 'Microsoft Intune'").AppId,(Get-AzureADServicePrincipal -Filter "DisplayName eq 'Microsoft Intune Enrollment'").AppId
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeUsers = "All"
            $conditions.Users.ExcludeUsers = "GuestsOrExternalUsers",(Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'").ObjectId
            #$conditions.Users.ExcludeGroups = $ExcludeCAGroup
            $conditions.Users.ExcludeRoles = (Get-AzureADDirectoryRoleTemplate).ObjectId
            $conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
            $conditions.Locations = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessLocationCondition
            $conditions.Locations.IncludeLocations = "All"
            $conditions.Locations.ExcludeLocations = "Alltrusted"
            $controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $controls._Operator = "OR"
            $controls.BuiltInControls = @('MFA')
            $sessions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessSessionControls
            $sessions.SignInFrequency = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessSignInFrequency
            $sessions.SignInFrequency.Value = "14"
            $sessions.SignInFrequency.Type = "Days"
            $sessions.SignInFrequency.IsEnabled = "true"
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls -SessionControls $sessions
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
 Write-LogSection '' -NoHostOutput

}

Function Start-BlockUnmanagedDownloads {
     <#
        .Synopsis
         Create CA to block downloads in unmanaged devices.
        
        .Description
         This function will create Conditional Access to block downloads in unmanaged devices.
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Block Unmanaged File Downloads",
	[String]$GroupExclude = "Harden365 - CA Exclusion - BlockUnmanagedDownloads Exclude"   
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name

    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = (Get-AzureADServicePrincipal -Filter "DisplayName eq 'Office 365 Exchange Online'").AppId,(Get-AzureADServicePrincipal -Filter "DisplayName eq 'Office 365 SharePoint Online'").AppId
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeUsers = "All"
            $conditions.Users.ExcludeUsers = (Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'").ObjectId
            $conditions.Users.ExcludeGroups = $ExcludeCAGroup
            $conditions.ClientAppTypes = @('Browser')
            $sessions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessSessionControls
            $sessions.ApplicationEnforcedRestrictions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationEnforcedRestrictions
            $sessions.ApplicationEnforcedRestrictions.IsEnabled = "true"
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -SessionControls $sessions
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
 Write-LogSection '' -NoHostOutput

}

Function Start-UnsupportedDevicePlatforms {
     <#
        .Synopsis
         Create CA to Unsupported Device Platforms.
        
        .Description
         This function will create Conditional Access to Unsupported Device Platforms.
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Unsupported Device Platforms",
	[String]$GroupExclude = "Harden365 - CA Exclusion - Unsupported Device Platforms Exclude"   
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name
    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeUsers = "All"
            $conditions.Users.ExcludeUsers = (Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'").ObjectId
            $conditions.Users.ExcludeGroups = $ExcludeCAGroup
            $conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
            $conditions.Platforms = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPlatformCondition
            $conditions.Platforms.IncludePlatforms = "All"
            $conditions.Platforms.ExcludePlatforms = @('Android','IOS','Windows','MacOS')
            $Controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $Controls._Operator = "OR"
            $Controls.BuiltInControls = "Block"
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
 Write-LogSection '' -NoHostOutput

}

Function Start-MobileDeviceAccessRequirements {
     <#
        .Synopsis
         Create CA to Mobile Device Access Requirements.
        
        .Description
         This function will create Conditional Access to Mobile Device Access Requirements.
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Mobile Device Access Requirements",
	[String]$GroupExclude = "Harden365 - CA Exclusion - Mobile Device Access Requirements"   
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name
    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Applications.ExcludeApplications = (Get-AzureADServicePrincipal -Filter "DisplayName eq 'Microsoft Intune'").AppId,(Get-AzureADServicePrincipal -Filter "DisplayName eq 'Microsoft Intune Enrollment'").AppId
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeUsers = "All"
            $conditions.Users.ExcludeUsers = (Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'").ObjectId
            $conditions.ClientAppTypes = 'MobileAppsAndDesktopClients'
            $conditions.Platforms = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPlatformCondition
            $conditions.Platforms.IncludePlatforms = @('Android','IOS')
            $Controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $Controls._Operator = "OR"
            $Controls.BuiltInControls = 'approvedApplication'
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
 Write-LogSection '' -NoHostOutput

}

Function Start-MobileAppsandDesktopClients {
     <#
        .Synopsis
         Create CA to Mobile Apps and Desktop Clients.
        
        .Description
         This function will create Conditional Access to Mobile Apps and Desktop Clients.
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Mobile Apps and Desktop Clients",
	[String]$GroupExclude = "Harden365 - CA Exclusion - Mobile Apps and Desktop Clients"   
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name
    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Applications.ExcludeApplications = (Get-AzureADServicePrincipal -Filter "DisplayName eq 'Microsoft Teams Services'").AppId
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeUsers = "All"
            $conditions.Users.ExcludeUsers = (Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'").ObjectId
            $conditions.ClientAppTypes = 'MobileAppsAndDesktopClients'
            $conditions.Platforms = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessPlatformCondition
            $conditions.Platforms.IncludePlatforms = @('Android','IOS')
            $Controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $Controls._Operator = "OR"
            $Controls.BuiltInControls = @('compliantDevice','domainJoinedDevice')
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
 Write-LogSection '' -NoHostOutput

}

Function Start-GuestAccessRestricted {
     <#
        .Synopsis
         Create CA to users connection.
        
        .Description
         This function will create Conditional Access Guest Access (Allowed Apps Excluded).
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Guest Access Restricted",
	[String]$GroupExclude = "Harden365 - CA Exclusion - Guest Access Restricted"   
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name

    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Applications.ExcludeApplications = 'Office365',(Get-AzureADServicePrincipal -Filter "DisplayName eq 'Microsoft Rights Management Services'").AppId,(Get-AzureADServicePrincipal -Filter "DisplayName eq 'My Apps'").AppId
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeUsers = "GuestsOrExternalUsers"
            $conditions.Users.ExcludeUsers = (Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'").ObjectId
            #$conditions.Users.ExcludeGroups = $ExcludeCAGroup
            $conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
            $controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $controls._Operator = "OR"
            $controls.BuiltInControls = @('Block')
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
 Write-LogSection '' -NoHostOutput

}

Function Start-HighRiskUsers {
     <#
        .Synopsis
         Create CA to users connection.
        
        .Description
         This function will create Conditional Access for High-Risk Users.
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - High-Risk Users",
	[String]$GroupExclude = "Harden365 - CA Exclusion - High-Risk Users Exclude"   
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name

    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeUsers = "All"
            $conditions.Users.ExcludeUsers = (Get-AzureADUser -Filter "userPrincipalName eq 'admin@$DomainOnM365'").ObjectId
            $conditions.UserRiskLevels = "High"
            #$conditions.Users.ExcludeGroups = $ExcludeCAGroup
            $conditions.ClientAppTypes = 'All'
            $controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $controls._Operator = "AND"
            $controls.BuiltInControls = @('MFA','passwordChange')
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
 Write-LogSection '' -NoHostOutput

}

Function Start-HighRiskSignIn {
     <#
        .Synopsis
         Create CA to users connection.
        
        .Description
         This function will create Conditional Access for High-Risk SignIn.
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - High-Risk SignIn",
	[String]$GroupExclude = "Harden365 - CA Exclusion - High-Risk SignIn Exclude"   
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name

    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeUsers = "All"
            $conditions.Users.ExcludeUsers = (Get-AzureADUser -Filter "userPrincipalName eq 'admin@$DomainOnM365'").ObjectId
            $conditions.SignInRiskLevels = "High"
            #$conditions.Users.ExcludeGroups = $ExcludeCAGroup
            $conditions.ClientAppTypes = 'All'
            $controls = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessGrantControls
            $controls._Operator = "OR"
            $controls.BuiltInControls = @('MFA')
            New-AzureADMSConditionalAccessPolicy -DisplayName $Name -State "Disabled" -Conditions $conditions -GrantControls $controls
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "Conditional Access '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "Conditional Access '$Name' already created!"
                  }
 Write-LogSection '' -NoHostOutput

}