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


Function Start-EmergencyAccount1 {
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
	[String]$Name = "Harden365 - Emergency Account 1",
    [Boolean]$UpperCase = $true,
    [Boolean]$LowerCase = $true,
    [Boolean]$Digits = $true,
    [Boolean]$SpecialCharacters = $true,
    [String]$ExcludeCharacters = "@",
    [String]$Lengt = "48",
    [String]$Title = "Brice_Glass"
)

Write-LogSection 'EMERGENCY ACCOUNTS' -NoHostOutput

#CHECKIS ADMIN	
               $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
               $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
               if (!$isAdmin) {
               Write-LogError 'You must run this script as an administrator to install or execute PoshKeepass module'
               Write-LogError 'Script execution cancelled'
               Pause;break }

#POSHKEEPASS INSTALL MODULE	
try { Get-InstalledModule -Name PoShKeePass -ErrorAction Stop > $null}
    catch {  
                Write-LogInfo "Installing PoshKeepass Module!"
                Install-Module -Name PoShKeePass -Force -WarningAction:SilentlyContinue
                Import-Module -Name PoShKeePass -WarningAction:SilentlyContinue
                }

#SCRIPT
$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -match $true }).Id
$dateString = Get-Date -Format "yyyyMMdd"
    if ((Get-MgUser).UserPrincipalName -eq "brice.glass@$DomainOnM365")
        {
        Write-LogWarning "User 'brice.glass@$DomainOnM365' already created!"      
    }
    else { 
            Try {
            Remove-KeePassDatabaseConfiguration -DatabaseProfileName "Harden365_uadmin" -Confirm:$false
            Copy-Item -Path ".\Config\Harden365.kp" -Destination "$DomainOnM365\Harden365-$dateString.kdbx"
            New-KeePassDatabaseConfiguration -DatabaseProfileName "Harden365_uadmin" -DatabasePath ".\$DomainOnM365\Harden365-$dateString.kdbx" -UseMasterKey
            $SecureString128=ConvertTo-SecureString "Harden365" -AsPlainText -Force
            if ($null -eq (Get-KeePassEntry -DatabaseProfileName "Harden365_uadmin" -KeePassEntryGroupPath "Harden365" -Title $Title -MasterKey $SecureString128))
            {
            $Pass_uadmin = New-KeePassPassword -UpperCase:$UpperCase -LowerCase:$LowerCase -Digits:$Digits -SpecialCharacters:$SpecialCharacters  -ExcludeCharacters:$ExcludeCharacters -Length $Lengt
            $SecureString128=ConvertTo-SecureString "Harden365" -AsPlainText -Force
            New-KeePassEntry -DatabaseProfileName "Harden365_uadmin" -KeePassEntryGroupPath "Harden365" -Title $Title -UserName "brice.glass@$DomainOnM365" -KeePassPassword $Pass_uadmin -MasterKey $SecureString128
            $U_PasswordProfile = @{
              Password = (Get-KeePassEntry -AsPlainText -DatabaseProfileName "Harden365_uadmin" -Title $Title -MasterKey $SecureString128).Password
              ForceChangePasswordNextSignIn = $False
              }
            New-MgUser -DisplayName $Title -PasswordProfile $U_PasswordProfile -UserPrincipalName "brice.glass@$DomainOnM365" -AccountEnabled -MailNickName $Title
            Import-Module Microsoft.Graph.Identity.Governance
            Remove-KeePassDatabaseConfiguration -DatabaseProfileName "Harden365_uadmin" -Confirm:$false
            $uadmin = Get-MgUser -UserId "brice.glass@$DomainOnM365"
            $globalAdmin = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Global Administrator'"
            Start-Sleep -Seconds 10
            $params = @{
            	"@odata.type" = "#microsoft.graph.unifiedRoleAssignment"
            	RoleDefinitionId = $globalAdmin.Id
            	PrincipalId = $uadmin.Id
            	DirectoryScopeId = "/"
            }
            New-MgRoleManagementDirectoryRoleAssignment -BodyParameter $params
            Write-LogInfo "User 'brice.glass@$DomainOnM365' created"
            } else {
            Write-LogWarning "User 'brice.glass@$DomainOnM365' already created"}
            }
                 Catch {
                        Write-LogError "User 'brice.glass@$DomainOnM365' not created"
                       }
          }
}

Function Start-EmergencyAccount2 {
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
	[String]$Name = "Harden365 - Emergency Account 2",
    [Boolean]$UpperCase = $true,
    [Boolean]$LowerCase = $true,
    [Boolean]$Digits = $true,
    [Boolean]$SpecialCharacters = $true,
    [String]$ExcludeCharacters = "@",
    [String]$Lengt = "48",
    [String]$Title = "Brice_Douglass"
)


#SCRIPT
$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -match $true }).Id
$dateString = Get-Date -Format "yyyyMMdd"
    if ((Get-MgUser).UserPrincipalName -eq "brice.douglass@$DomainOnM365")
        {
        Write-LogWarning "User 'brice.douglass@$DomainOnM365' already created!"      
    }
    else { 
            Try {
            Remove-KeePassDatabaseConfiguration -DatabaseProfileName "Harden365_uadmin" -Confirm:$false
            New-KeePassDatabaseConfiguration -DatabaseProfileName "Harden365_uadmin" -DatabasePath ".\$DomainOnM365\Harden365-$dateString.kdbx" -UseMasterKey
            $SecureString128=ConvertTo-SecureString "Harden365" -AsPlainText -Force
            if ($null -eq (Get-KeePassEntry -DatabaseProfileName "Harden365_uadmin" -KeePassEntryGroupPath "Harden365" -Title $Title -MasterKey $SecureString128))
            {
            $Pass_uadmin = New-KeePassPassword -UpperCase:$UpperCase -LowerCase:$LowerCase -Digits:$Digits -SpecialCharacters:$SpecialCharacters  -ExcludeCharacters:$ExcludeCharacters -Length $Lengt
            $SecureString128=ConvertTo-SecureString "Harden365" -AsPlainText -Force
            New-KeePassEntry -DatabaseProfileName "Harden365_uadmin" -KeePassEntryGroupPath "Harden365" -Title $Title -UserName "brice.douglass@$DomainOnM365" -KeePassPassword $Pass_uadmin -MasterKey $SecureString128
            $U_PasswordProfile = @{
              Password = (Get-KeePassEntry -AsPlainText -DatabaseProfileName "Harden365_uadmin" -Title $Title -MasterKey $SecureString128).Password
              ForceChangePasswordNextSignIn = $False
              }
            New-MgUser -DisplayName $Title -PasswordProfile $U_PasswordProfile -UserPrincipalName "brice.douglass@$DomainOnM365" -AccountEnabled -MailNickName $Title
            Remove-KeePassDatabaseConfiguration -DatabaseProfileName "Harden365_uadmin" -Confirm:$false
            Import-Module Microsoft.Graph.Identity.Governance
            $uadmin = Get-MgUser -UserId "brice.douglass@$DomainOnM365"
            $globalAdmin = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Global Administrator'"
            Start-Sleep -Seconds 10
            $params = @{
            	"@odata.type" = "#microsoft.graph.unifiedRoleAssignment"
            	RoleDefinitionId = $globalAdmin.Id
            	PrincipalId = $uadmin.Id
            	DirectoryScopeId = "/"
            }
            New-MgRoleManagementDirectoryRoleAssignment -BodyParameter $params
            Write-LogInfo "User 'brice.douglass@$DomainOnM365' created"
            } else {
            Write-LogWarning "User 'brice.douglass@$DomainOnM365' already created"}
            }
                 Catch {
                        Write-LogError "User 'brice.douglass@$DomainOnM365' not created"
                       }
          }
}

Function Start-TiersAdminNoExpire {
     <#
        .Synopsis
         This function configure never expire password
        
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
$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -match $true }).Id

     if ((Get-MgUser).UserPrincipalName -eq "brice.glass@$DomainOnM365")
        {
         Try {
              Start-Sleep -Seconds 5
              Update-MgUser -UserId "brice.glass@$DomainOnM365" -PasswordPolicies DisablePasswordExpiration
              Write-LogInfo "User 'brice.glass@$DomainOnM365' never expires"
              }
                 Catch {
                        Write-LogError "User 'brice.glass@$DomainOnM365' not configured to never expire"
                       }
        }
    else { 
          Write-LogWarning "User 'brice.glass@$DomainOnM365' not exist"
          }

     if ((Get-MgUser).UserPrincipalName -eq "brice.douglass@$DomainOnM365")
        {
         Try {
              Start-Sleep -Seconds 5
              Update-MgUser -UserId "brice.douglass@$DomainOnM365" -PasswordPolicies DisablePasswordExpiration
              Write-LogInfo "User 'brice.douglass@$DomainOnM365' never expires"
              }
                 Catch {
                        Write-LogError "User 'brice.douglass@$DomainOnM365' not configured to never expire"
                       }
        }
    else { 
          Write-LogWarning "User 'brice.douglass@$DomainOnM365' not exist"
          }

}
  
Function Start-TiersAdminNoSSPR {
     <#
        .Synopsis
         This function disable SSPR for admins
        
        .Description
         This function disable SSPR for admins

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
	[String]$Name = "Harden365 - Disable SSPR for Admins Account"
)


#SCRIPT
$DomainOnM365=(Get-MgDomain | Where-Object { $_.IsInitial -match $true }).Id


     if ((Get-MgPolicyAuthorizationPolicy).AllowedToUseSspr -eq $true)
        {
         Write-LogWarning "SSPR is enable for Admin Accounts"
         Update-MgPolicyAuthorizationPolicy -AllowedToUseSspr:$false
         Write-LogInfo "SSPR for Admin Accounts disabled"
        }
    
 Write-LogSection '' -NoHostOutput

}




