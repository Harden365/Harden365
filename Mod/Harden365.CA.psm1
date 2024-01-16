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
    [String]$mailNickName = "H365-MFAUsersExclude"
)


#SCRIPT
$GroupAAD=Get-MgGroup -Filter "DisplayName eq '$Name'"
    if (-not $GroupAAD)
        {
        Try {
            New-MgGroup -Description "$Name" -DisplayName "$Name" -MailEnabled:$false -SecurityEnabled -MailNickName $MailNickName
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

Function Start-GroupMFAGuestsExclude {
     <#
        .Synopsis
         Create group to exclude guests.
        
        .Description
         This function will create new group to exclude MFA.

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - CA Exclusion - MFA Guests Exclude",
    [String]$mailNickName = "H365-MFAGuestExclude"
)


#SCRIPT
$GroupAAD=Get-MgGroup -Filter "DisplayName eq '$Name'"
    if (-not $GroupAAD)
        {
        Try {
            New-MgGroup -Description "$Name" -DisplayName "$Name" -MailEnabled:$false -SecurityEnabled -MailNickName $MailNickName
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

Function Start-GroupLegacyAuthGroupExclude {
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
$GroupAAD=Get-MgGroup -Filter "DisplayName eq '$Name'"
    if (-not $GroupAAD)
        {
        Try {
            New-MgGroup -Description "$Name" -DisplayName "$Name" -MailEnabled:$false -SecurityEnabled -MailNickName $MailNickName
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

Function Start-GroupUnsupportedDevicePlatforms {
     <#
        .Synopsis
         Create group to Unsupported Device Platforms.
        
        .Description
         This function will create new group to exclude Unsupported Device Platforms .

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - CA Exclusion - Unsupported Device Platforms Exclude",
    [String]$mailNickName = "H365-UnsupportedOSExclude"
)


#SCRIPT
$GroupAAD=Get-MgGroup -Filter "DisplayName eq '$Name'"
    if (-not $GroupAAD)
        {
        Try {
            New-MgGroup -Description "$Name" -DisplayName "$Name" -MailEnabled:$false -SecurityEnabled -MailNickName $MailNickName
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
$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -eq $true }).Id
$ExcludeCAGroup = (Get-MgGroup -All | Where-Object { $_.DisplayName -eq $GroupExclude }).Id
$CondAccPol=Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$name'"
$idBriceGlass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.glass@$domainOnM365" }).Id
$idBriceDouglass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.douglass@$domainOnM365" }).Id
    if (-not $CondAccPol){
        Try {
            $params = @{
	                displayName = "$Name"
	                state = "disabled"
	                conditions = @{
		                clientAppTypes = @(
                            "exchangeActiveSync",
                            "other"
		                )
		                applications = @{
			                includeApplications = @(
				            "All"
			                )
		                }
		                users = @{
                            includeUsers = @(
				            "All"
			                )
                        excludeUsers = @(
				            "$idBriceGlass"
                            "$idBriceDouglass"
			                )
                        excludeGroups = @(
                            "$ExcludeCAGroup"
			                )
		                }
	                }
	                grantControls = @{
		                operator = "OR"
		                builtInControls = @(
                        "block"
		                )
	                }
            }

            New-MgIdentityConditionalAccessPolicy -BodyParameter $params
            Write-LogInfo "CA '$Name' created"
            }
                 Catch {
                        Write-LogError "CA '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "CA '$Name' already created"
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
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Global Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Global Reader"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Application Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Authentication Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Billing Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Cloud Application Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Conditional Access Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Exchange Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Helpdesk administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Password administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Privileged authentication administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Privileged Role Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Security administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "SharePoint administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "User administrator"}).Id)

$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -eq $true }).Id
$CondAccPol=Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$name'"
$idBriceGlass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.glass@$domainOnM365" }).Id
$idBriceDouglass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.douglass@$domainOnM365" }).Id
    if (-not $CondAccPol){
        Try {
            $params = @{
	                displayName = "$Name"
	                state = "disabled"
	                conditions = @{
		                clientAppTypes = @(
                            "Browser"
                            "MobileAppsAndDesktopClients"
		                )
		                applications = @{
			                includeApplications = @(
				            "All"
			                )
		                }
		                users = @{
                            includeRoles = $CARoles
                        excludeUsers = @(
				            "$idBriceGlass"
                            "$idBriceDouglass"
			                )
		                }
	                }
	                grantControls = @{
		                operator = "OR"
		                builtInControls = @(
                        "mfa"
                        )
	                }
	                sessionControls = @{
                        disableResilienceDefaults = "false"
                        applicationEnforcedRestrictions = $null
                        cloudAppSecurity = $null
		                SignInFrequency = @{
			                Value = "4"
                            type = "hours"
                            authenticationType = "primaryAndSecondaryAuthentication"
                            frequencyInterval = "timeBased"
                            isEnabled ="true"
		                }
		                PersistentBrowser = @{
			                mode = "never"
                            isEnabled = "true"
		                }
                    }
            }

            New-MgIdentityConditionalAccessPolicy -BodyParameter $params
            Write-LogInfo "CA '$Name' created"
            }
                 Catch {
                        Write-LogError "CA '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "CA '$Name' already created!"
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
$ExcludeCAGroup = (Get-MgGroup -All | Where-Object { $_.DisplayName -eq $GroupExclude }).Id
$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -eq $true }).Id
$CondAccPol=Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$name'"
$idBriceGlass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.glass@$domainOnM365" }).Id
$idBriceDouglass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.douglass@$domainOnM365" }).Id
$CARoles = @(
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Global Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Global Reader"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Application Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Authentication Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Billing Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Cloud Application Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Conditional Access Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Exchange Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Helpdesk administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Password administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Privileged authentication administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Privileged Role Administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Security administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "SharePoint administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "User administrator"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Directory synchronization accounts"}).Id,
(Get-MgDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Hybrid Identity administrator"}).Id)

    if (-not $CondAccPol){
        Try {
            $params = @{
	                displayName = "$Name"
	                state = "disabled"
	                conditions = @{
		                clientAppTypes = @(
                            "Browser"
                            "MobileAppsAndDesktopClients"
		                )
		                applications = @{
			                includeApplications = @(
				            "All"
			                )
		                }
		                users = @{
                            includeUsers = @(
                                "All"
                                )
                            excludeUsers = @(
                                "GuestsOrExternalUsers"
				                "$idBriceGlass"
                                "$idBriceDouglass"
			                    )
                            excludeGroups = @(
                                $ExcludeCAGroup
			                    )
                            excludeRoles = @(
                                $CARoles
			                    )
		                }
	                }
	                grantControls = @{
		                operator = "OR"
		                builtInControls = @(
                        "mfa"
                        )
	                }
	                sessionControls = @{
                        disableResilienceDefaults = "false"
                        applicationEnforcedRestrictions = $null
                        cloudAppSecurity = $null
		                SignInFrequency = @{
			                Value = "7"
                            type = "days"
                            authenticationType = "primaryAndSecondaryAuthentication"
                            frequencyInterval = "timeBased"
                            isEnabled ="true"
		                }
                    }
            }
            New-MgIdentityConditionalAccessPolicy -BodyParameter $params
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "CA '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "CA '$Name' already created!"
                  }
}

Function Start-MFAGuests {
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
	[String]$Name = "Harden365 - MFA Guests",
	[String]$GroupExclude = "Harden365 - CA Exclusion - MFA Guests Exclude"   
)


#SCRIPT
$ExcludeCAGroup = (Get-MgGroup -All | Where-Object { $_.DisplayName -eq $GroupExclude }).Id
$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -eq $true }).Id
$CondAccPol=Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$name'"
$idBriceGlass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.glass@$domainOnM365" }).Id
$idBriceDouglass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.douglass@$domainOnM365" }).Id

    if (-not $CondAccPol){
        Try {
            $params = @{
	                displayName = "$Name"
	                state = "disabled"
	                conditions = @{
		                clientAppTypes = @(
                            "Browser"
                            "MobileAppsAndDesktopClients"
		                )
		                applications = @{
			                includeApplications = @(
				            "All"
			                )
		                }
		                users = @{
                            includeUsers = @(
                                "GuestsOrExternalUsers"
                                )
                            excludeUsers = @(
				                "$idBriceGlass"
                                "$idBriceDouglass"
			                    )
                            excludeGroups = @(
                                $ExcludeCAGroup
			                    )
		                }
	                }
	                grantControls = @{
		                operator = "OR"
		                builtInControls = @(
                        "mfa"
                        )
	                }
	                sessionControls = @{
                        disableResilienceDefaults = "false"
                        applicationEnforcedRestrictions = $null
                        cloudAppSecurity = $null
		                SignInFrequency = @{
			                Value = "7"
                            type = "days"
                            authenticationType = "primaryAndSecondaryAuthentication"
                            frequencyInterval = "timeBased"
                            isEnabled ="true"
		                }
                    }
            }
            New-MgIdentityConditionalAccessPolicy -BodyParameter $params
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "CA '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "CA '$Name' already created!"
                  }
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
$ExcludeCAGroup = (Get-MgGroup -All | Where-Object { $_.DisplayName -eq $GroupExclude }).Id
$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -eq $true }).Id
$CondAccPol=Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$name'"
$idBriceGlass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.glass@$domainOnM365" }).Id
$idBriceDouglass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.douglass@$domainOnM365" }).Id
    if (-not $CondAccPol){
        Try {
            $params = @{
	                displayName = "$Name"
	                state = "disabled"
	                conditions = @{
		                clientAppTypes = @(
                            "Browser"
                            "MobileAppsAndDesktopClients"
		                )
		                applications = @{
			                includeApplications = @(
				            "All"
			                )
		                }
		                users = @{
                            includeUsers = @(
                                "All"
                                )
                            excludeUsers = @(
                                "GuestsOrExternalUsers"
				                "$idBriceGlass"
                                "$idBriceDouglass"
			                    )
                            excludeGroups = @(
                                $ExcludeCAGroup
			                    )
		                }
                        platforms = @{
                            includePlatforms = @(
                                "All"
                                )
                            excludePlatforms = @(
                                "Android"
                                "iOS"
                                "windows"
                                "macOS"
                                )
	                    }
                    }
	                grantControls = @{
		                operator = "OR"
		                builtInControls = @(
                        "block"
                        )
	                }
            }
            New-MgIdentityConditionalAccessPolicy -BodyParameter $params
            Write-LogInfo "CA '$Name' created"
            }
                 Catch {
                        Write-LogError "CA '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "CA '$Name' already created!"
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
	[String]$Name = "Harden365 - Mobile Device Access Requirements"  
)


#SCRIPT
$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -eq $true }).Id
$CondAccPol=Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$name'"
$idBriceGlass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.glass@$domainOnM365" }).Id
$idBriceDouglass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.douglass@$domainOnM365" }).Id
    if (-not $CondAccPol){
        Try {
               $params = @{
	                displayName = "$Name"
	                state = "disabled"
	                conditions = @{
		                clientAppTypes = @(
                            "MobileAppsAndDesktopClients"
		                )
		                applications = @{
			                includeApplications = @(
				            "All"
			                )
		                }
		                users = @{
                            includeUsers = @(
                                "All"
                                )
                            excludeUsers = @(
				                "$idBriceGlass"
                                "$idBriceDouglass"
			                    )
		                }
                        platforms = @{
                            includePlatforms = @(
                                "Android"
                                "iOS"
                                )
	                    }
	                }
	                grantControls = @{
		                 operator = "OR"
		                 builtInControls = @(
                         "approvedApplication",
                         "compliantApplication"

                         )
	                }
            }
            New-MgIdentityConditionalAccessPolicy -BodyParameter $params
            Write-LogInfo "CA '$Name' created"
            }
                 Catch {
                        Write-LogError "CA '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "CA '$Name' already created!"
                  }
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
	[String]$Name = "Harden365 - Mobile Apps and Desktop Clients"  
)


#SCRIPT
$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -eq $true }).Id
$CondAccPol=Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$name'"
$idBriceGlass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.glass@$domainOnM365" }).Id
$idBriceDouglass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.douglass@$domainOnM365" }).Id
$idTeamsService = (Get-MgServicePrincipal -Filter "DisplayName eq 'Microsoft Teams Services'").AppId
    if (-not $CondAccPol){
        Try {
               $params = @{
	                displayName = "$Name"
	                state = "disabled"
	                conditions = @{
		                clientAppTypes = @(
                            "MobileAppsAndDesktopClients"
		                )
		                applications = @{
			                includeApplications = @(
				            "All"
			                )
			                excludeApplications = @(
				            "$idTeamsService"
			                )
		                }
		                users = @{
                            includeUsers = @(
                                "All"
                                )
                            excludeUsers = @(
				                "$idBriceGlass"
                                "$idBriceDouglass"
			                    )
		                }
                        platforms = @{
                            includePlatforms = @(
                                "Android"
                                "iOS"
                                )
	                    }
	                }
	                grantControls = @{
		                 operator = "OR"
		                 builtInControls = @(
                         "compliantDevice"
                         )
	                }
            }
            New-MgIdentityConditionalAccessPolicy -BodyParameter $params
            Write-LogInfo "Conditional Access '$Name' created"
            }
                 Catch {
                        Write-LogError "CA '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "CA '$Name' already created!"
                  }
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
	[String]$Name = "Harden365 - High-Risk Users"  
)


#SCRIPT
if (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "AAD_PREMIUM_P2")
    { 
$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -eq $true }).Id
$CondAccPol=Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$name'"
$idBriceGlass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.glass@$domainOnM365" }).Id
$idBriceDouglass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.douglass@$domainOnM365" }).Id

    if (-not $CondAccPol){
        Try {
            $params = @{
	                displayName = "$Name"
	                state = "disabled"
	                conditions = @{
		                clientAppTypes = @(
                            "All"
		                )
		                applications = @{
			                includeApplications = @(
				            "All"
			                )
		                }
		                users = @{
                            includeUsers = @(
                                "All"
                                )
                            excludeUsers = @(
				                "$idBriceGlass"
                                "$idBriceDouglass"
			                    )
		                }
		                UserRiskLevels = @(
                            "High"
		                )
	                }
	                grantControls = @{
		                operator = "AND"
		                builtInControls = @(
                        "mfa"
                        "passwordChange"
                        )
	                }
            }
            New-MgIdentityConditionalAccessPolicy -BodyParameter $params
            Write-LogInfo "CA '$Name' created"
            }
                 Catch {
                        Write-LogError "CA '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "CA '$Name' already created!"
                  }
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
	[String]$Name = "Harden365 - High-Risk SignIn"
)

#SCRIPT
if (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "AAD_PREMIUM_P2")
    { 
$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -eq $true }).Id
$CondAccPol=Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$name'"
$idBriceGlass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.glass@$domainOnM365" }).Id
$idBriceDouglass = (Get-MgUser -All | Where-Object { $_.UserPrincipalName -eq "brice.douglass@$domainOnM365" }).Id

    if (-not $CondAccPol){
        Try {
            $params = @{
	                displayName = "$Name"
	                state = "disabled"
	                conditions = @{
		                clientAppTypes = @(
                            "All"
		                )
		                applications = @{
			                includeApplications = @(
				            "All"
			                )
		                }
		                users = @{
                            includeUsers = @(
                                "All"
                                )
                            excludeUsers = @(
				                "$idBriceGlass"
                                "$idBriceDouglass"
			                    )
		                }
		                SignInRiskLevels = @(
                            "High"
                            "Medium"
		                )
	                }
	                grantControls = @{
		                operator = "AND"
		                builtInControls = @(
                        "mfa"
                        )
	                }
            }
            New-MgIdentityConditionalAccessPolicy -BodyParameter $params
            Write-LogInfo "CA '$Name' created"
            }
                 Catch {
                        Write-LogError "CA '$Name' not created"
                        }
            }
            else { 
                  Write-LogWarning "CA '$Name' already created!"
                  }
 }
}

 