


#region Authentification
$appId = $(Get-AzureADApplication -Filter "DisplayName eq 'Harden365 App'").AppId
$tenantId = $(Get-AzureADTenantDetail).ObjectId
$appSecret = "ZTJiNGY3MWQtYjEzNS00NTJkLTkyYWQtNzRlNzU3ZmEyY2Vm"
$deviceId = "ef1378c4d1315419471577b1d9373e87fa580026"

$resourceAppIdUri = 'https://api.securitycenter.microsoft.com'
$oAuthUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$body = [Ordered] @{
    resource = "$resourceAppIdUri"
    client_id = "$appId"
    client_secret = "$appSecret"
    grant_type = 'client_credentials'
}
$response = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $body -ErrorAction Stop
$aadToken = $response.access_token


$url = "https://api.securitycenter.microsoft.com/api/Machines/$deviceid/offboard"
$headers = @{ 
    'Content-Type' = 'application/json'
    Accept = 'application/json'
    Authorization = "Bearer $aadToken" 
}
$body = ConvertTo-Json -InputObject @{ 'Comment' = 'Offboard machine by Harden365' }
try {
    $webResponse = Invoke-WebRequest -Method Post -Uri $url -Headers $headers -Body $body -ErrorAction Stop
    $response =  $webResponse | ConvertFrom-Json
    $results = $response.Status
    } catch {}
if ($results -eq 'pending') {
    write-host 'Pending offboarding for'$deviceId
    }
