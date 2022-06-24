
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

# SECURITY CONFIGURATION CATEGORIES
$graphApiVersion = "Beta"
$ESP_resource = "deviceManagement/intents/$policyId/categories/$categoryId/settings?`$expand=Microsoft.Graph.DeviceManagementComplexSettingInstance/Value"

# GROUP
$graphApiVersion = "v1.0"
$ESP_resource = "Groups"

#region CONNECT GRAPH
$uri = "https://graph.microsoft.com/$graphApiVersion/$($ESP_resource)"
$APIcollections=(Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $uri -Method Get).value
#endregion

#$APIcollections | select-Object DisplayName,'@odata.type'

foreach($APIcollection in $APIcollections){
    write-host "convert '$DisplayName' to json"
    $JsonExport = ConvertTo-Json $APIcollection -Depth 5
    $JsonConvert =  $JsonExport | ConvertFrom-Json
    $JsonFile = ($JsonConvert.displayName) -replace '\<|\>|:|"|/|\\|\||\?|\*', "_"
    $JsonExport | Set-Content -LiteralPath ".\Logs\$("$JsonFile" + "_" + $(get-date -f dd-MM-yyyy-H-mm-ss) + ".json")"
    }

