Function Start-PolicyConfigExport {
     <#
        .Synopsis
         PolicyConfigExport
        
        .Description
         This function will 

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
)


#region Authentification
$ApplicationID = $(Get-AzureADApplication -Filter "DisplayName eq 'Harden365 App'").AppId
$TenantDomainName = $(Get-AzureADTenantDetail).ObjectId
$AccessSecret = "YjhlNjA1NWQtOWVmMC00ZjEyLWJmMDQtMTEyOGI1YjdhZWZm"

$Body = @{
Grant_Type    = "client_credentials"
Scope         = "https://graph.microsoft.com/.default"
client_Id     = $ApplicationID
Client_Secret = $AccessSecret
}
$ConnectGraph = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantDomainName/oauth2/v2.0/token -Method POST -Body $Body
$token = $ConnectGraph.access_token
#endregion


# SECURITY CONFIGURATION
$graphApiVersion = "Beta"
$ESP_resource = "deviceManagement/grouppolicyconfigurations"

#region CONNECT GRAPH
$uri = "https://graph.microsoft.com/$graphApiVersion/$($ESP_resource)"
$APIcollections=(Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $uri -Method Get).value
#endregion

foreach($APIcollection in $APIcollections){
    $APIcollectionName = $APIcollection.DisplayName
    write-host "convert '$APIcollectionName' to json"
    $JsonExport = ConvertTo-Json $APIcollection -Depth 5
    $JsonConvert =  $JsonExport | ConvertFrom-Json
    $JsonFile = ($JsonConvert.DisplayName) -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"
    $JsonExport | Set-Content -LiteralPath ".\Logs\$("$JsonFile" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".json")"
    }

}


Function Start-SecurityConfigExport {
     <#
        .Synopsis
         Enable Unified Audit Log
        
        .Description
         This function will

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
)


#region Authentification
$ApplicationID = $(Get-AzureADApplication -Filter "DisplayName eq 'Harden365 App'").AppId
$TenantDomainName = $(Get-AzureADTenantDetail).ObjectId
$AccessSecret = "YjhlNjA1NWQtOWVmMC00ZjEyLWJmMDQtMTEyOGI1YjdhZWZm"

$Body = @{
Grant_Type    = "client_credentials"
Scope         = "https://graph.microsoft.com/.default"
client_Id     = $ApplicationID
Client_Secret = $AccessSecret
}
$ConnectGraph = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantDomainName/oauth2/v2.0/token -Method POST -Body $Body
$token = $ConnectGraph.access_token
#endregion


# SECURITY CONFIGURATION
$graphApiVersion = "Beta"
$ESP_resource = "deviceManagement/intents"

#region CONNECT GRAPH
$uri = "https://graph.microsoft.com/$graphApiVersion/$($ESP_resource)"
$APIcollections=(Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $uri -Method Get).value
#endregion

foreach($APIcollection in $APIcollections){
    $APIcollectionName = $APIcollection.DisplayName
    write-host "convert '$APIcollectionName' to json"
    $JsonExport = ConvertTo-Json $APIcollection -Depth 5
    $JsonConvert =  $JsonExport | ConvertFrom-Json
    $JsonFile = ($JsonConvert.DisplayName) -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"
    $JsonExport | Set-Content -LiteralPath ".\Logs\$("$JsonFile" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".json")"
    }

}