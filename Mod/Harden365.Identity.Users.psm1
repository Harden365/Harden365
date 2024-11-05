
###################################################################
## Get-MSOAuditUsers                                             ##
## ---------------------------                                   ##
## This function will audit users details in AAD                 ##
## and export result in html and csv                             ##
##                                                               ##
## Version: 01.00.000                                            ##
##  Author: contact@harden365.net                                ##
###################################################################
Function Get-MSOAuditUsers {
     <#
        .Synopsis
         Audit Users Details
        
        .Description
         ## This function will audit users details in AAD and export result in html and csv
        
        .Notes
         Version: 01.00 -- 
         
    #>

Write-LogSection 'AUDIT USERS' -NoHostOutput

#SCRIPT

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
    h3 {
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
</style>
"@

######################################################################


#IMPORT LICENSE SKU
Write-LogInfo "Import all Sku/productNames Licensing"
$licenseCsvURL = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'
$licenseHashTable = @{}
$ProductDisplayName = "???Product_Display_Name"
(Invoke-WebRequest -Uri $licenseCsvURL).ToString() | ConvertFrom-Csv | ForEach-Object {
    $licenseHashTable[$_.$ProductDisplayName] = @{
        "SkuId" = $_.GUID
        "SkuPartNumber" = $_.String_Id
        "DisplayName" = $_.$ProductDisplayName
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
    $licenses = $null
    If (Get-MgUserLicenseDetail -USerId $User.id) {
    $licenses = (Get-MgUserLicenseDetail -UserId $User.id).SkuPartNumber -join ", "
    ForEach ($item in $licenseHashTable.Values) {
        if ($Licenses -match $item.skupartnumber) {
            $licenses = $licenses.replace($item.skupartnumber,$item.DisplayName)
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
                    if ($methods -eq $null) {
                    $methods = $methodAuthType} else {
                    $methods = $methods,$methodAuthType -join ", "}
                    }
                    }
                    } catch {}
     
    $obj = [pscustomobject][ordered]@{
            DisplayName              = $user.DisplayName
            UserPrincipalName        = $user.UserPrincipalName
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
    write-progress -Activity "Processing report..." -Status "Users: $i of $($Users.Count)" -percentComplete (($i / $users.Count)  * 100)
    } 
    write-progress -Activity "Processing report..." -status "Users: $i" -Completed


######################################################################


     
$dateFileString = Get-Date -Format "FileDateTimeUniversal"

$Report | Sort-Object  UserPrincipalName | Select-object DisplayName,UserPrincipalName,Licenses,Sync,passwordneverExpires,LastSignInDate,LastPasswordChange ,Authentication `
 | Export-Csv -Path ".\$DomainOnM365\AuditUsersDetails$dateFileString.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation


#GENERATE HTML
$Report | Sort-Object  UserPrincipalName | Select-object DisplayName,UserPrincipalName,Licenses,Sync,passwordneverExpires,LastSignInDate,LastPasswordChange ,Authentication `
 | ConvertTo-Html -Property DisplayName,UserPrincipalName,Licenses,Sync,passwordneverExpires,LastSignInDate,LastPasswordChange ,Authentication `
    -PreContent "<h1>Audit Identity Users</h1>" "<h2>$DomainOnM365</h2>" -Head $Header -PostContent "<h2>$(Get-Date)</h2>"`
    | Out-File .\$DomainOnM365\Harden365-AuditUsersDetails$dateFileString.html

Invoke-Expression .\$DomainOnM365\Harden365-AuditUsersDetails$dateFileString.html 
Write-LogInfo "Audit Identity Users generated in folder .\$DomainOnM365"
Write-LogSection '' -NoHostOutput 
}

