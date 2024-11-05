
###################################################################
## Get-MSOAuditApplications                                      ##
## ---------------------------                                   ##
## This function will audit users details in AAD                 ##
## and export result in html and csv                             ##
##                                                               ##
## Version: 01.00.000                                            ##
##  Author: contact@harden365.net                                ##
###################################################################
Function Get-MSOAuditApplications {
     <#
        .Synopsis
         Audit Applications Details
        
        .Description
         ## This function will audit Applications details in Entra and export result in html and csv
        
        .Notes
         Version: 01.00 -- 
         
    #>

Write-LogSection 'AUDIT APPLICATIONS' -NoHostOutput

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


Write-LogInfo "Import All Applications"
$Report = [System.Collections.Generic.List[Object]]::new()
$EntraApps = Get-MgServicePrincipal -All
Write-LogInfo "$($EntraApps.count) applications imported"
Write-LogInfo "Generating report"

$Report = [System.Collections.Generic.List[Object]]::new()
$i = 0
ForEach ($EntraApp in $EntraApps) {

    $assignment = Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $EntraApp.Id
    $AllspOAuth2PermissionsGrants = $null
    $AllAssignment = $null
    $spOAuth2PermissionsGrants = (Get-MgOauth2PermissionGrant -All| Where-Object { $_.clientId -eq $EntraApp.Id }).Scope
    if ($spOAuth2PermissionsGrants -ne $null)
        {
        $AllspOAuth2PermissionsGrants = $spOAuth2PermissionsGrants -join ", "
        } 
    if ($assignment.PrincipalDisplayName -ne $null)
        {
        $AllAssignment = $assignment.PrincipalDisplayName -join ", "
        } 

    $obj = [pscustomobject][ordered]@{
            DisplayName                  = $EntraApp.AppDisplayName
            AppId                        = $EntraApp.AppId
            Owners                       = $EntraApp.Owners
            AppRoleAssignmentRequired    = $EntraApp.AppRoleAssignmentRequired
            AppRoleAssignment            = $AllAssignment
            PreferredSingleSignOnMode    = $EntraApp.PreferredSingleSignOnMode
            SSOEndDateTime               = $EntraApp.PasswordCredentials.EndDateTime
            PermissionsGrants            = $AllspOAuth2PermissionsGrants
        }
    $report.Add($obj)
    $i++
    $percentComplete = [math]::Round(($i/$EntraApps.count)*100,2)
    write-progress -Activity "Processing report..." -Status "Applications : $i of $($EntraApps.Count)" -percentComplete (($i / $EntraApps.Count)  * 100)

}
write-progress -Activity "Processing report..." -status "Applications : $i" -Completed




######################################################################


     
$dateFileString = Get-Date -Format "FileDateTimeUniversal"

$Report | Sort-Object DisplayName | Where-Object {($_.Owners -ne $null) -or ($_.PreferredSingleSignOnMode -ne $null) -or ($_.AppRoleAssignmentRequired -eq $true) -or ($_.AppRoleAssignment -ne $null) -or ($_.PermissionsGrants -ne $null)} `
  | Export-Csv -Path ".\$DomainOnM365\AuditApplicationsDetails$dateFileString.csv" -Delimiter ';' -Encoding UTF8 -NoTypeInformation



#GENERATE HTML
$Report | Sort-Object DisplayName | Where-Object {($_.Owners -ne $null) -or ($_.PreferredSingleSignOnMode -ne $null) -or ($_.AppRoleAssignmentRequired -eq $true) -or ($_.AppRoleAssignment -ne $null) -or ($_.PermissionsGrants -ne $null)} `
 | ConvertTo-Html -Property DisplayName,AppId,Owners,AppRoleAssignmentRequired,AppRoleAssignment ,PreferredSingleSignOnMode,SSOEndDateTime,PermissionsGrants `
    -PreContent "<h1>Audit Identity Applications</h1>" "<h2>$DomainOnM365</h2>" -Head $Header -PostContent "<h2>$(Get-Date)</h2>"`
    | Out-File .\$DomainOnM365\Harden365-AuditApplicationsDetails$dateFileString.html

Invoke-Expression .\$DomainOnM365\Harden365-AuditApplicationsDetails$dateFileString.html 
Write-LogInfo "Audit Identity Applications generated in folder .\$DomainOnM365"
Write-LogSection '' -NoHostOutput 
}

