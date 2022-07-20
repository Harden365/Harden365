<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.MDERemoveDevice.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   07/20/2022
        Last Updated: 07/20/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Remove device from MDE

    .DESCRIPTION

#>

Function Start-MDERemoveDevice {
     <#
        .Synopsis
         DeviceConfigImport
        
        .Description
         This function will 

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
    [String]$AccessSecret
)

Write-LogSection 'MDE REMOVE DEVICE' -NoHostOutput

#region Authentification
$appId = $(Get-AzureADApplication -Filter "DisplayName eq 'Harden365 App'").AppId
$tenantId = $(Get-AzureADTenantDetail).ObjectId
write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("Please insert DeviceId :") -NoNewline -ForegroundColor Yellow ; $deviceId = Read-Host

$resourceAppIdUri = 'https://api.securitycenter.microsoft.com'
$oAuthUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$body = [Ordered] @{
    resource = "$resourceAppIdUri"
    client_id = "$appId"
    client_secret = "$AccessSecret"
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
    } catch { write-LogError 'Error API WebRequest' }
if ($results -eq 'pending') {
    write-LogInfo 'Pending offboarding for'$deviceId
    }
else {}

Write-LogSection '' -NoHostOutput  
}