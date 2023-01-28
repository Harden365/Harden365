
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
    $DomainOnM365 = (Get-AzureADDomain | Where-Object { $_.IsInitial -match $true }).Name

    #TENANT EDITION
    if (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne '0' } | Select-Object -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match 'AAD_PREMIUM_P2') {
        $TenantEdition = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne '0' } | Select-Object -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match 'AAD_PREMIUM_P2' }).ServiceName
        $TenantEdition = 'Azure AD Premium P2' 
    }    
    elseif (((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne '0' } | Select-Object -ExpandProperty ServiceStatus).ServicePlan).ServiceName -match 'AAD_PREMIUM') {
        $TenantEdition = ((Get-MsolAccountSku | Where-Object { $_.ActiveUnits -ne '0' } | Select-Object -ExpandProperty ServiceStatus).ServicePlan | Where-Object { $_.ServiceName -match 'AAD_PREMIUM' }).ServiceName
        $TenantEdition = 'Azure AD Premium P1' 
    }  



    $header = @"
<img src="$pwd\Config\Harden365.logohtml" alt="logoHarden365" class="centerImage" alt="CH Logo" height="167" width="500">
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


    $RolesCollection = @()
    $Roles = Get-AzureADDirectoryRole

    if ($TenantEdition -eq $null) {
        Try {
            ForEach ($Role In $Roles) {
                $Members = Get-AzureADDirectoryRoleMember -ObjectId $Role.ObjectId 
                ForEach ($Member In $Members) {
                    $UPN = $Member.UserPrincipalName
                    Write-LogInfo "Check $UPN"
                    Start-Sleep -Seconds 1
                    $objrole = New-Object PSObject -Property @{
                        ObjectId          = $Member.ObjectId
                        'Role Name'       = $Role.DisplayName
                        Name              = $Member.DisplayName
                        UserPrincipalName = $Member.UserPrincipalName
                        MemberType        = $Member.UserType
                        Enabled           = $Member.AccountEnabled
                        'When Created'    = ($Member.ExtensionProperty).createdDateTime
                    }
                    $RolesCollection += $objrole
                }
            }
        }
        catch {
            Write-LogError ' Roles Collection building error'
        }
    }
    else {
        Try {
            ForEach ($Role In $Roles) {
                $Members = Get-AzureADDirectoryRoleMember -ObjectId $Role.ObjectId 
                ForEach ($Member In $Members) {
                    $UPN = $Member.UserPrincipalName
                    Write-LogInfo "Check $UPN"
                    Start-Sleep -Seconds 1
                    $objrole = New-Object PSObject -Property @{
                        ObjectId          = $Member.ObjectId
                        'Role Name'       = $Role.DisplayName
                        Name              = $Member.DisplayName
                        UserPrincipalName = $Member.UserPrincipalName
                        MemberType        = $Member.UserType
                        Enabled           = $Member.AccountEnabled
                        'When Created'    = ($Member.ExtensionProperty).createdDateTime
                    }
                    $RolesCollection += $objrole
                }
            }
        }
        catch {
            Write-LogError ' Roles Collection building error'
        }
    }




    try {
        $UsersCollection = @()
        $Users = Get-MsolUser -All | Select-Object ObJectId, UserPrincipalName, LastPasswordChangeTimestamp, PasswordNeverExpires, ImmutableId, StrongAuthenticationMethods, `
        @{Name = 'PhoneNumbers'; Expression = { ($_.StrongAuthenticationUserDetails).PhoneNumber } },
        @{Name = 'LicensePlans'; Expression = { (($_.licenses).Accountsku).SkupartNumber } }
        foreach ($user in $Users) {
            $objuser = New-Object PSObject -Property @{
                ObjectId             = $user.ObjectId
                IsLicensed           = if ($user.LicensePlans) {
                    $True
                }
                else {
                    $False
                }
                ADSync               = if ($user.ImmutableId) {
                    $True
                }
                else {
                    $False
                }
                PasswordNeverExpires = $user.PasswordNeverExpires
                PasswordLastChange   = $user.LastPasswordChangeTimestamp
                MFAEnforced          = $(if ($user.StrongAuthenticationRequirements) {
                        $True
                    }
                    else {
                        $False
                    })
                MFAEnabled           = if ($user.StrongAuthenticationMethods) {
                    $True
                }
                else {
                    $False
                }
                MFAMethod            = (($user.StrongAuthenticationMethods) | Where-Object { $_.IsDefault -eq $true }).MethodType
                PhoneNumbers         = $user.PhoneNumbers
            }
            $UsersCollection += $objuser
        }
    }
    catch {
        Write-LogError ' Users Collection building error'
    }
  
    foreach ($item in $RolesCollection) {
        foreach ($obj in $item) {
            $obj | Add-Member -MemberType NoteProperty -Name 'Password Last Change' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).PasswordLastChange
            $obj | Add-Member -MemberType NoteProperty -Name 'StrongAuthenticationMethod' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).StrongAuthenticationMethod
            $obj | Add-Member -MemberType NoteProperty -Name 'Never Expire' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).PasswordNeverExpires
            $obj | Add-Member -MemberType NoteProperty -Name 'AD Sync' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).ADSync
            $obj | Add-Member -MemberType NoteProperty -Name 'MFA Configured' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).MFAEnabled
            $obj | Add-Member -MemberType NoteProperty -Name 'MFA Primary Method' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).MFAMethod
            $obj | Add-Member -MemberType NoteProperty -Name 'MFA per User' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).MFAEnforced
            $obj | Add-Member -MemberType NoteProperty -Name 'Phone Number' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).PhoneNumbers
            $obj | Add-Member -MemberType NoteProperty -Name 'Is Licensed' -Value ($UsersCollection | Where-Object { $_.ObjectId -eq $obj.ObjectId }).IsLicensed
            if (
            ($Obj.'Is Licensed' -eq $true) -or
            ($Obj.'AD Sync' -eq $true) -or
            (($Obj.'Never Expire' -eq $true) -and ($Obj.'MFA Configured' -eq $false))
            ) {
                $obj | Add-Member -MemberType NoteProperty -Name 'Check' -Value 'Warning'
            }
            else {
                $obj | Add-Member -MemberType NoteProperty -Name 'Check' -Value 'Healthy'
            }
        }
    }


    $Export = $RolesCollection | Where-Object { $null -ne $_.MemberType } | Sort-Object UserPrincipalName, 'Role Name'


    #GENERATE HTML
    mkdir -Force '.\Audit' | Out-Null
    $dateFileString = Get-Date -Format 'FileDateTimeUniversal'
    $export | ConvertTo-Html -Property 'Check', 'Role Name', Enabled, UserPrincipalName, Name, 'Is Licensed', 'AD Sync', 'Last Logon (30d)', 'Never Expire', 'Password Last Change', 'MFA per User', 'MFA Configured', 'MFA Primary Method', 'Phone Number', 'When Created' `
        -PreContent '<h1>Audit Roles and Administrators</h1>' "<h2>$DomainOnM365</h2>" -Head $Header -Title 'Harden 365 - Audit' -PostContent "<h2>$(Get-Date -UFormat '%d-%m-%Y %T ')</h2>"`
    | ForEach-Object { $PSItem -replace '<td>Warning</td>', "<td style='color: #cc0000;font-weight: bold'>Warning</td>" }`
    | ForEach-Object { $PSItem -replace '<td>Healthy</td>', "<td style='color: #32cd32;font-weight: bold'>Healthy</td>" }`
    | Out-File .\Audit\AuditRoles$dateFileString.html

    $Export | Sort-Object UserPrincipalName, 'Role Name' | Select-Object 'Check', 'Role Name', Enabled, UserPrincipalName, Name, 'Is Licensed', 'AD Sync', 'Last Logon (30d)', 'Never Expire', 'Password Last Change', 'MFA per User', 'MFA Configured', 'MFA Primary Method', 'Phone Number', 'When Created' | Export-Csv -Path `
        ".\Audit\AuditRolesDetails$dateFileString.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    Invoke-Expression .\Audit\AuditRoles$dateFileString.html
    Write-LogInfo 'Audit Roles Administration generated in folder .\Audit'
    Write-LogSection '' -NoHostOutput
}