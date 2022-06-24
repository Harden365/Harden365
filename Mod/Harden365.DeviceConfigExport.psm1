<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.DeviceConfigExport.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   06/15/2022
        Last Updated: 06/15/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Export to JSON Device configuration setting

    .DESCRIPTION
        Create SharedMailbox for alerts
        Create group for autoforward excluded
        Create group for Antispam strict policy
        Create Antispam Strict Policy and Rule
        Create Antispam Standard Policy and Rule
        Create Antiforward Standard Policy and Rule
        Create Antimalware Policy and Rule
        Create transport rules to warm user for Office files with macro
        Create transport rules to skip filtering Antispam by domains.
        Prevent share details calendar
        Enable Unified Audit Log
#>

Function Start-DeviceConfigExport {
     <#
        .Synopsis
         DeviceConfigExport
        
        .Description
         This function will 

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
)

Write-LogSection 'DEVICE CONFIGURATION EXPORT' -NoHostOutput


#region Authentification
$ApplicationID = $(Get-AzureADApplication -Filter "DisplayName eq 'Harden365 App'").AppId
$TenantDomainName = $(Get-AzureADTenantDetail).ObjectId
$AccessSecret = "YjhlNjA1NWQtOWVmMC00ZjEyLWJmMDQtMTEyOGI1YjdhZWZm"
#$AccessSecret = $($PasswordCredential).Value

$Body = @{
Grant_Type    = "client_credentials"
Scope         = "https://graph.microsoft.com/.default"
client_Id     = $ApplicationID
Client_Secret = $AccessSecret
}
$ConnectGraph = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantDomainName/oauth2/v2.0/token -Method POST -Body $Body
$token = $ConnectGraph.access_token
#endregion


# DEVICE CONFIGURATION
$graphApiVersion = "Beta"
$ESP_resource = "deviceManagement/deviceConfigurations"

#region CONNECT GRAPH
$uri = "https://graph.microsoft.com/$graphApiVersion/$($ESP_resource)"
$APIcollections=(Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $uri -Method Get).value
#endregion

#$APIcollections | select-Object DisplayName,'@odata.type'

foreach($APIcollection in $APIcollections){
    $APIcollectionName = $APIcollection.displayName
    write-host "convert '$APIcollectionName' to json"
    $JsonExport = ConvertTo-Json $APIcollection -Depth 5
    $JsonConvert =  $JsonExport | ConvertFrom-Json
    $JsonFile = ($JsonConvert.displayName) -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"
    $JsonExport | Set-Content -LiteralPath ".\Logs\$("$JsonFile" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".json")"
    }

}




