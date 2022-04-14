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
         Create group for exclude users.
        
        .Description
         This function will create new group for exclude MFA.

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - MFA Users Exclude",
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
         Create group for legacy authentification.
        
        .Description
         This function will create new group for exclude LegacyAuth .

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Legacy Authentification Exclude",
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
         Create CA for legacy authentification.
        
        .Description
         This function will create Conditional Access Block for Legacy auth.

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Block Legacy Authentification",
	[String]$GroupExclude = "Harden365 - Legacy Authentification Exclude"
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
         Create CA for admins connection.
        
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
$ExcludeCARoles = (Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq "Directory Synchronization Accounts" -or $_.DisplayName -eq "Hybrid Identity Administrator"}).ObjectId
$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name

    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeRoles = (Get-AzureADDirectoryRoleTemplate).ObjectId
            $conditions.Users.ExcludeRoles = $ExcludeCARoles
            $conditions.Users.ExcludeUsers = (Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'").ObjectId
            $conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
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
}

Function Start-MFAUsers {
     <#
        .Synopsis
         Create CA for users connection.
        
        .Description
         This function will create Conditional Access MFA for Users.
        
        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - MFA Users",
	[String]$GroupExclude = "Harden365 - MFA Users Exclude"   
)


#SCRIPT
$ExcludeCAGroup = (Get-AzureADGroup -All $true | Where-Object DisplayName -eq $GroupExclude).ObjectId
$CondAccPol=Get-AzureADMSConditionalAccessPolicy | Where-Object DisplayName -eq $Name

    if (-not $CondAccPol){
        Try {
            $conditions = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessConditionSet
            $conditions.Applications = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessApplicationCondition
            $conditions.Applications.IncludeApplications = "All"
            $conditions.Users = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessUserCondition
            $conditions.Users.IncludeUsers = "All"
            $conditions.Users.ExcludeUsers = "GuestsOrExternalUsers"
            $conditions.Users.ExcludeGroups = $ExcludeCAGroup
            $conditions.Users.ExcludeRoles = (Get-AzureADDirectoryRoleTemplate).ObjectId
            $conditions.ClientAppTypes = @('Browser', 'MobileAppsAndDesktopClients')
            $conditions.Locations = New-Object -TypeName Microsoft.Open.MSGraph.Model.ConditionalAccessLocationCondition
            $conditions.Locations.IncludeLocations = "All"
            $conditions.Locations.ExcludeLocations = "Alltrusted"
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
