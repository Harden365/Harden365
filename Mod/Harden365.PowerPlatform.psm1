<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.PowerPlatform.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   05/06/2022
        Last Updated: 05/06/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening PowerPlatform

    .DESCRIPTION
        Create CA for admins connection
        Create group for exclude users
        Create CA for users connection
        Create group for legacy authentification
        Create CA for legacy authentification
#>



Function Start-BlockSubscriptionFree {
     <#
        .Synopsis
         Disable suscription free licence by users.
        
        .Description
         Disable suscription free licence by userA.

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
    [String]$mailNickName = "H365-MFAExclude"
)

Write-LogSection 'POWERPLATFORM' -NoHostOutput

#SCRIPT

Set-MsolCompanySettings -AllowAdHocSubscriptions $false

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

