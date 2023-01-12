<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.TierModel.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 01/17/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening Tier Model

    .DESCRIPTION
        Create Emergency Account
        Create Global Admin Account
        Modify account in never expire password 
#>


Function Start-Tiers0EmergencyAccount {
     <#
        .Synopsis
         create user with Global admin assignment.
        
        .Description
         This function will create new account with global admin rule

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Emergency Account",
    [Boolean]$UpperCase = $true,
    [Boolean]$LowerCase = $true,
    [Boolean]$Digits = $true,
    [Boolean]$SpecialCharacters = $true,
    [String]$ExcludeCharacters = "@",
    [String]$Lengt = "24",
    [String]$Title = "0Tiers_EmergencyAccount"
)

Write-LogSection 'TIER MODEL' -NoHostOutput


#POSHKEEPASS INSTALL MODULE	
$poshkeepassinstalled = $false
try {
    Get-KeePassDatabaseConfiguration | Out-Null    
    $poshkeepassinstalled = $true
} catch {} 
if (-not $poshkeepassinstalled) {
    Write-LogInfo "Installing PoshKeepass Module!"
    Install-Module -Name PoShKeePass -Force
}


#SCRIPT

$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
    if ((Get-AzureADUser).UserPrincipalName -eq "u-admin@$DomainOnM365")
        {
        Write-LogWarning "User 'u-admin@$DomainOnM365' already created!"      
    }
    else { 
            Try {
            Remove-KeePassDatabaseConfiguration -DatabaseProfileName "Harden365_uadmin" -Confirm:$false
            New-KeePassDatabaseConfiguration -DatabaseProfileName "Harden365_uadmin" -DatabasePath ".\Keepass\Harden365.kdbx" -UseMasterKey
            $SecureString128=ConvertTo-SecureString "Harden365" -AsPlainText -Force
            if ((Get-KeePassEntry -DatabaseProfileName "Harden365_uadmin" -KeePassEntryGroupPath "Harden365" -Title $Title -MasterKey $SecureString128) -eq $null)
            {
            $Pass_uadmin = New-KeePassPassword -UpperCase:$UpperCase -LowerCase:$LowerCase -Digits:$Digits -SpecialCharacters:$SpecialCharacters  -ExcludeCharacters:$ExcludeCharacters -Length $Lengt
            $SecureString128=ConvertTo-SecureString "Harden365" -AsPlainText -Force
            New-KeePassEntry -DatabaseProfileName "Harden365_uadmin" -KeePassEntryGroupPath "Harden365" -Title $Title -UserName "u-admin@$DomainOnM365" -KeePassPassword $Pass_uadmin -MasterKey $SecureString128
            $U_PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
            $U_PasswordProfile.ForceChangePasswordNextLogin = $False
            $U_PasswordProfile.Password = (Get-KeePassEntry -AsPlainText -DatabaseProfileName "Harden365_uadmin" -Title $Title -MasterKey $SecureString128).Password
            New-AzureADUser -DisplayName $Title -PasswordProfile $U_PasswordProfile -UserPrincipalName "u-admin@$DomainOnM365" -AccountEnabled $true -MailNickName $Title
            Remove-KeePassDatabaseConfiguration -DatabaseProfileName "Harden365_uadmin" -Confirm:$false
            $uadmin = Get-AzureADUser -Filter "userPrincipalName eq 'u-admin@$DomainOnM365'"
            $globalAdmin = Get-AzureADMSRoleDefinition -Filter "displayName eq 'Global Administrator'"
            Start-Sleep -Seconds 10
            New-AzureADMSRoleAssignment -DirectoryScopeId '/' -RoleDefinitionId $globalAdmin.Id -PrincipalId $uadmin.objectId
            Write-LogInfo "User 'u-admin@$DomainOnM365' created"
            } else {
            Write-LogWarning "User 'u-admin@$DomainOnM365' already created"}
            }
                 Catch {
                        Write-LogError "User 'u-admin@$DomainOnM365' not created"
                       }
          }
}


Function Start-Tiers0GlobalAdminAccount {
     <#
        .Synopsis
         create user with Global admin assignment.
        
        .Description
         This function will create new account with global admin rule

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Global Admin Account",
    [Boolean]$UpperCase = $true,
    [Boolean]$LowerCase = $true,
    [Boolean]$Digits = $true,
    [Boolean]$SpecialCharacters = $true,
    [String]$ExcludeCharacters = "@",
    [String]$Lengt = "24",
    [String]$Title = "0Tiers_GlobalAdmin"
)


#POSHKEEPASS INSTALL MODULE	
$poshkeepassinstalled = $false
try {
    Get-KeePassDatabaseConfiguration | Out-Null    
    $poshkeepassinstalled = $true
} catch {} 
if (-not $poshkeepassinstalled) {
    Write-LogInfo "Installing PoshKeepass Module!" 
    Install-Module -Name PoShKeePass -Force
}

#SCRIPT

$DomainOnM365=(Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name
    if ((Get-AzureADUser).UserPrincipalName -eq "s-admin@$DomainOnM365")
        {
        Write-LogWarning "User 's-admin@$DomainOnM365' already created!"   
    }
    else { 
            Try {
            Remove-KeePassDatabaseConfiguration -DatabaseProfileName "Harden365_sadmin" -Confirm:$false
            New-KeePassDatabaseConfiguration -DatabaseProfileName "Harden365_sadmin" -DatabasePath ".\Keepass\Harden365.kdbx" -UseMasterKey
            $SecureString16=ConvertTo-SecureString "Harden365" -AsPlainText -Force
            if ((Get-KeePassEntry -DatabaseProfileName "Harden365_sadmin" -KeePassEntryGroupPath "Harden365" -Title $Title -MasterKey $SecureString16) -eq $null)
            {
            $Pass_sadmin = New-KeePassPassword -UpperCase:$UpperCase -LowerCase:$LowerCase -Digits:$Digits -SpecialCharacters:$SpecialCharacters  -ExcludeCharacters:$ExcludeCharacters -Length $Lengt
            $SecureString16=ConvertTo-SecureString "Harden365" -AsPlainText -Force
            New-KeePassEntry -DatabaseProfileName "Harden365_sadmin" -KeePassEntryGroupPath "Harden365" -Title $Title -UserName "s-admin@$DomainOnM365" -KeePassPassword $Pass_sadmin -MasterKey $SecureString16
            $S_PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
            $S_PasswordProfile.ForceChangePasswordNextLogin = $False
            $S_PasswordProfile.Password = (Get-KeePassEntry -AsPlainText -DatabaseProfileName "Harden365_sadmin" -Title $Title -MasterKey $SecureString16).Password
            New-AzureADUser -DisplayName $Title -PasswordProfile $S_PasswordProfile -UserPrincipalName "s-admin@$DomainOnM365" -AccountEnabled $true -MailNickName $Title
            Remove-KeePassDatabaseConfiguration -DatabaseProfileName "Harden365_sadmin" -Confirm:$false
            $sadmin = Get-AzureADUser -Filter "userPrincipalName eq 's-admin@$DomainOnM365'"
            $globalAdmin = Get-AzureADMSRoleDefinition -Filter "displayName eq 'Global Administrator'"
            Start-Sleep -Seconds 10
            New-AzureADMSRoleAssignment -DirectoryScopeId '/' -RoleDefinitionId $globalAdmin.Id -PrincipalId $sadmin.objectId
            Write-LogInfo "User 's-admin@$DomainOnM365' created"
            } else {
            Write-LogWarning "User 's-admin@$DomainOnM365' already created"}
            }
                 Catch {
                        Write-LogError "User 's-admin@$DomainOnM365' not created"
                       }
          }
}


Function Start-TiersAdminNoExpire {
     <#
        .Synopsis
         Remove users with Global admin assignment.
        
        .Description
         This function configure never expire password

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Config Admins Account"
)


#SCRIPT
$DomainOnM365=(Get-MsolDomain | Where-Object { $_.IsInitial -match $true}).Name
         Try {
           Set-MsolCompanySettings -SelfServePasswordResetEnabled $false
           Write-LogInfo "SSPR for Admin disabled"
           }
                 Catch {
                        Write-LogError "SSPR for Admin not disabled"
                       }

     if ((Get-MsolUser -All).UserPrincipalName -eq "u-admin@$DomainOnM365")
        {
         Try {
              Start-Sleep -Seconds 5
              Set-MsolUser -UserPrincipalName "u-admin@$DomainOnM365" -PasswordNeverExpires $true
              Write-LogInfo "User 'u-admin@$DomainOnM365' never expires"
              }
                 Catch {
                        Write-LogError "User 'u-admin@$DomainOnM365' not configured to never expire"
                       }
        }
    else { 
          Write-LogWarning "User 'u-admin@$DomainOnM365' not exist"
          }


     if ((Get-MsolUser -All).UserPrincipalName -eq "s-admin@$DomainOnM365")
        {
         Try {
              Start-Sleep -Seconds 5
              Set-MsolUser -UserPrincipalName "s-admin@$DomainOnM365" -PasswordNeverExpires $true
              Write-LogInfo "User 's-admin@$DomainOnM365' never expires"
              }
                 Catch {
                        Write-LogError "User 's-admin@$DomainOnM365' not configured to never expire"
                        }
        }
    else { 
          Write-LogWarning "User 's-admin@$DomainOnM365' not exist"
          }

 Write-LogSection '' -NoHostOutput

}

Write-LogInfo "Emergency Accounts credentials are saved in .\Keepass file"
Write-LogError "Password Keepass is : Harden365"    





