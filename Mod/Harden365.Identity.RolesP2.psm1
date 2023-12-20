
###################################################################
## Get-AADRolesAudit                                             ##
## ---------------------------                                   ##
## This function will audit roles adminsitation in AAD           ##
## and export result in html                                     ##
##                                                               ##
## Version: 01.00.000                                            ##
##  Author: contact@harden365.net                                ##
###################################################################
Function Get-AADRolesAudit {

#SCRIPT
Write-LogSection 'AUDIT ROLES' -NoHostOutput
$DomainOnM365 = (Get-MgDomain | Where-Object { $_.IsDefault -eq $true }).Id

$header = @"
<img src="https://hardenad.net/wp-content/uploads/2021/12/Logo-HARDEN-365-Horizontal-RVB@4x-300x85.png" alt="logoHarden365" class="centerImage" alt="CH Logo" height="85" width="300">
<style>
    h1 {
        font-family: Arial, Helvetica, sans-serif;
        color: #cc0000;
        font-size: 28px;
        text-align:center;
    }
    h2 {
        font-family: Arial, Helvetica, sans-serif;
        color: #000099;
        font-size: 16px;
        text-align:right;
    }
   table {
        margin: auto;
        font-size: 12px;
		border: 0px; 
		font-family: Arial, Helvetica, sans-serif;
	} 
    td {
        padding: 4px;
		margin: 0px;
		border: 0;
	}
    th {
        background: #395870;
        background: linear-gradient(#49708f, #293f50);
        color: #fff;
        font-size: 11px;
        text-transform: uppercase;
        padding: 10px 15px;
        vertical-align: middle;
	}
    tbody tr:nth-child(even) {
        background: #f0f0f2;
    }
    .footer
    { color:green;
    margin-left:25px;
    font-family:Tahoma;
    font-size:8pt;
    }
</style>
"@

#####################################################


#IMPORT LICENSE SKU
Write-LogInfo "import all Sku/productNames Licensing"
$licenseCsvURL = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'
$licenseHashTable = @{}
(Invoke-WebRequest -Uri $licenseCsvURL).ToString() | ConvertFrom-Csv | ForEach-Object {
    $licenseHashTable[$_.Product_Display_Name] = @{
        "SkuId" = $_.GUID
        "SkuPartNumber" = $_.String_Id
        "DisplayName" = $_.Product_Display_Name
    }
}

#IMPORT ROLE MEMBER
Write-LogInfo "Import Assigned Roles"
$i = 0
$roles = Get-MgDirectoryRole
$rolemembers = [System.Collections.Generic.List[Object]]::new()
foreach ($role in $roles) {
        $obj = [pscustomobject][ordered]@{
        "roleDisplayName" = $role.DisplayName
        "roleId" = $role.id
        "membersid" = (Get-MgDirectoryRoleMember -DirectoryRoleId $role.id).Id
        }
        $rolemembers.Add($obj)
        $i++
        write-progress -Activity "Processing report..." -Status "Roles: $i of $($roles.Count)" -percentComplete (($i / $roles.Count)  * 100)
        }

#IMPORT ROLE ELIGIBLE MEMBER
$EligibleAADUserData = @()
$EligibleAADGroupData = @()
Import-Module -Name Microsoft.Graph.Identity.Governance -Force
$AllEligible = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -ExpandProperty "*" -All
$AllAssignments = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -ExpandProperty "*" -All
#$AllGroupsEligible = Get-MgIdentityGovernancePrivilegedAccessGroupEligibilitySchedule -Filter "groupId eq 'e76a884a-0f92-4b2a-9959-a6e18031411f'" | fl
#$AllGroupsEligible = Get-MgIdentityGovernancePrivilegedAccessGroupEligibilitySchedule -Filter "PrincipalId eq 'ab5987bd-6df0-44af-b563-1efa496bc9a1'" | fl

foreach($Role in $AllEligible){

    If($Role.Principal.AdditionalProperties.'@odata.type' -eq "#microsoft.graph.user"){
        $UserProperties = [pscustomobject]@{
            displayName = $Role.Principal.AdditionalProperties.displayName
            UserPrincipalName = $Role.Principal.AdditionalProperties.userPrincipalName
            StartDateTime = $Role.StartDateTime
            EndDateTime = $(If($null -eq $Role.EndDateTime){"Permanent"}else{$Role.EndDateTime})
            RoleName = $Role.RoleDefinition.DisplayName
        }
        $EligibleAADUserData += $UserProperties
    }
}

foreach($Role in $AllAssignments){
        If($Role.Principal.AdditionalProperties.'@odata.type' -eq "#microsoft.graph.group"){
        $GroupProperties= [pscustomobject]@{
            displayName = $Role.Principal.AdditionalProperties.displayName
            mailNickname = $Role.Principal.AdditionalProperties.mailNickname
            securityIdentifier = $Role.Principal.AdditionalProperties.securityIdentifier
            RoleName = $Role.RoleDefinition.DisplayName
        }
        $EligibleAADGroupData += $GroupProperties
        }
    }


Write-LogInfo "Import All Users"
$Users = Get-MgUser -all -Property UserPrincipalName, PasswordPolicies, DisplayName, id,OnPremisesSyncEnabled,lastPasswordChangeDateTime,SignInActivity,Authentication
Write-LogInfo "$($Users.count) users imported"
Write-LogInfo "Generating report"
$Report = [System.Collections.Generic.List[Object]]::new()
$i = 0
ForEach ($user in $Users) {
    # LICENSES
    If (Get-MgUserLicenseDetail -USerId $User.id) {
    $licenses = $null
    $licenses = (Get-MgUserLicenseDetail -UserId $User.id).SkuPartNumber -join ", "
    ForEach ($item in $licenseHashTable.Values) {
        if ($Licenses -match $item.skupartnumber) {
            $licenses = $licenses.replace($item.skupartnumber,$item.DisplayName)
            }
            }
    }

    # ROLES ACTIVE
    $AffectedRoles = $null
    $affectedType = $null
    ForEach ($item in $rolemembers) {
        if ($item.membersid -like $user.id) {
            if ($null -eq $AffectedRoles) {
            $AffectedRoles = $item.roleDisplayName
            $affectedType = "Active"
            } else {
            $AffectedRoles = $AffectedRoles,$item.roleDisplayName -join ", "
            $affectedType = $affectedType,"Active" -join ", "
            }
            }
            }
    
    # ROLES ELIGIBLE
    $AffectedEndDate = $null
    ForEach ($item in $EligibleAADUserData) {
        if ($item.UserPrincipalName -like $user.UserPrincipalName) {
            if ($null -eq $AffectedEndDate) {
            $AffectedRoles = $item.roleName
            $affectedType = "Eligible"
            $AffectedEndDate = $item.EndDateTime
            } else {
            $AffectedRoles = $AffectedRoles,$item.roleName -join ", "
            $affectedType = $affectedType,"Eligible" -join ", "
            $AffectedEndDate = $AffectedEndDate,$item.EndDateTime -join ", "
            }
            }
            }

    # ROLES GROUP
    ForEach ($item in $EligibleAADGroupData) {
        $GroupId = (Get-MgGroup -Filter "displayName eq '$($item.DisplayName)'").Id
        $GroupMember = Get-MgGroupMember -GroupId $GroupId -ExpandProperty "*" -All
        ForEach ($groupmemberitem in $GroupMember )
        {
            if ($groupmemberitem.id -like $User.id) {
                if ($null -eq $AffectedRoles) {
                $AffectedRoles = $item.roleName
                $affectedType = "Group:$($item.DisplayName)"
                } else {
                $AffectedRoles = $AffectedRoles,$item.roleName -join ", "
                $affectedType = $affectedType,"Group:$($item.DisplayName)" -join ", "
            }
            }
         }
    }

    # METHODS
                try {
                $methods = $null
                $DeviceList = $null
                $methodAuthType = $null
                $DeviceList = Get-MgUserAuthenticationMethod -UserId $User.id
                $DeviceOutput = foreach ($Device in $DeviceList) {
 
                    #Converting long method to short-hand human readable method type.
                    switch ($Device.AdditionalProperties["@odata.type"]) {
                        '#microsoft.graph.microsoftAuthenticatorAuthenticationMethod'  {
                            $MethodAuthType     = 'AuthenticatorApp'+"-"+$Device.AdditionalProperties["displayName"]
                            $AdditionalProperties = $Device.AdditionalProperties["displayName"]
                        }
 
                        '#microsoft.graph.phoneAuthenticationMethod'                   {
                            $MethodAuthType     = 'PhoneAuthentication'+"-"+$Device.AdditionalProperties["phoneType", "phoneNumber"] -join ' '
                            $AdditionalProperties = $Device.AdditionalProperties["phoneType", "phoneNumber"] -join ' '
                        }
 
                        #'#microsoft.graph.passwordAuthenticationMethod'                {
                        #    $MethodAuthType     = 'passwordAuthentication'
                        #    $AdditionalProperties = $Device.AdditionalProperties["displayName"]
                        #}
 
                        '#microsoft.graph.fido2AuthenticationMethod'                   {
                            $MethodAuthType     = 'Fido2'+"-"+$Device.AdditionalProperties["model"]
                            $AdditionalProperties = $Device.AdditionalProperties["model"]
                        }
 
                        '#microsoft.graph.windowsHelloForBusinessAuthenticationMethod' {
                            $MethodAuthType     = 'WindowsHelloForBusiness'+"-"+$Device.AdditionalProperties["displayName"]
                            $AdditionalProperties = $Device.AdditionalProperties["displayName"]
                        }
 
                        '#microsoft.graph.emailAuthenticationMethod'                   {
                            $MethodAuthType     = 'EmailAuthentication'+"-"+$Device.AdditionalProperties["emailAddress"]
                            $AdditionalProperties = $Device.AdditionalProperties["emailAddress"]
                        }
 
                        '#microsoft.graph.temporaryAccessPassAuthenticationMethod'        {
                            $MethodAuthType     = 'TemporaryAccessPass'
                            $AdditionalProperties = 'TapLifetime:' + $Device.AdditionalProperties["lifetimeInMinutes"] + 'm - Status:' + $Device.AdditionalProperties["methodUsabilityReason"]
                        }
 
                        '#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod' {
                            $MethodAuthType     = 'Passwordless'+"-"+$Device.AdditionalProperties["displayName"]
                            $AdditionalProperties = $Device.AdditionalProperties["displayName"]
                        }
 
                        '#microsoft.graph.softwareOathAuthenticationMethod' {
                            $MethodAuthType     = 'SoftwareOath'+"-"+$Device.AdditionalProperties["displayName"]
                            $AdditionalProperties = $Device.AdditionalProperties["displayName"]
                        }
                    }
                    if ($MethodAuthType -ne 'PhoneAuthentication'){
                    if ($null -eq $methods) {
                    $methods = $methodAuthType} else {
                    $methods = $methods,$methodAuthType -join ", "}
                    }
                    }
                    } catch {}
     
    $obj = [pscustomobject][ordered]@{
            DisplayName              = $user.DisplayName
            UserPrincipalName        = $user.UserPrincipalName
            Roles                    = $affectedRoles
            RolesType                = $affectedType
            RolesEndDate             = $AffectedEndDate
            Licenses                 = $licenses
            Sync                     = if ($user.OnPremisesSyncEnabled) {"true"} else {"false"}
            passwordneverExpires     = ($user | Select-Object @{N="PasswordNeverExpires";E={$_.PasswordPolicies -contains "DisablePasswordExpiration"}}).PasswordNeverExpires
            LastSignInDate           = ($user).SignInActivity.LastSignInDateTime
            LastPasswordChange       = $user.lastPasswordChangeDateTime
            Authentication           = $methods
        }
    $report.Add($obj)
    $i++
    $percentComplete = [math]::Round(($i/$Users.count)*100,2)
    write-progress -Activity "Processing report..." -Status "Users: $i of $($Users.Count)" -percentComplete $percentComplete
    write-progress -Activity "Processing report..." -status "Users: $i" -Completed
    } 



#####################################################


$dateFileString = Get-Date -Format "FileDateTimeUniversal"
mkdir -Force ".\Audit" | Out-Null
$Report | Where-Object {$null -ne $_.Roles} | Sort-Object  UserPrincipalName | Select-object DisplayName,UserPrincipalName,Roles,RolesType,RolesEndDate,Licenses,Sync,passwordneverExpires,LastSignInDate,LastPasswordChange ,Authentication `
 | Export-Csv -Path ".\Audit\AuditAdminsDetails$dateFileString.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation


#GENERATE HTML
$Report | Where-Object {$null -ne $_.Roles} | Sort-Object  UserPrincipalName | Select-object DisplayName,UserPrincipalName,Roles,RolesType,RolesEndDate,Licenses,Sync,passwordneverExpires,LastSignInDate,LastPasswordChange ,Authentication `
 | ConvertTo-Html -Property DisplayName,UserPrincipalName,Roles,RolesType,RolesEndDate,Licenses,Sync,LastSignInDate,Authentication `
    -PreContent "<h1>Audit Identity Admins</h1>" "<h2>$DomainOnM365</h2>" -Head $Header -PostContent "<h2>$(Get-Date)</h2>"`
    | Out-File .\Audit\Harden365-AuditAdminsDetails$dateFileString.html

Invoke-Expression .\Audit\Harden365-AuditAdminsDetails$dateFileString.html 
Write-LogInfo "Audit Identity Admins generated in folder .\Audit"
Write-LogSection '' -NoHostOutput 
}
