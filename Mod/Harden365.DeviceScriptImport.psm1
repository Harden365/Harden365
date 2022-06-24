#region Authentification
$ApplicationID = $(Get-AzureADApplication -Filter "DisplayName eq 'Harden365 App'").AppId
$TenantDomainName = $(Get-AzureADTenantDetail).ObjectId
#Jeff
#$AccessSecret = "YjhlNjA1NWQtOWVmMC00ZjEyLWJmMDQtMTEyOGI1YjdhZWZm"
#Demo
$AccessSecret = "ZDIyYjFlMjctOTliYy00MTUxLTljMDItYjYyMzllOGMyZjlm"
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


Function Add-DeviceManagementScript() {
    <#
.SYNOPSIS
This function is used to add a device management script using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a device management script
.EXAMPLE
Add-DeviceManagementScript -File "path to powershell-script file"
Adds a device management script from a File in Intune
Add-DeviceManagementScript -File "URL to powershell-script file" -URL
Adds a device management script from a URL in Intune
.NOTES
NAME: Add-DeviceManagementScript
#>
    [cmdletbinding()]
    Param (
        # Path or URL to Powershell-script to add to Intune
        [Parameter(Mandatory = $true)]
        [string]$File,
        # PowerShell description in Intune
        [Parameter(Mandatory = $false)]
        [string]$Description,
        # Set to true if it is a URL
        [Parameter(Mandatory = $false)]
        [switch][bool]$URL = $false
    )
    if ($URL -eq $true) {
        $FileName = $File -split "/"
        $FileName = $FileName[-1]
        $OutFile = "$env:TEMP\$FileName"
        try {
            Invoke-WebRequest -Uri $File -UseBasicParsing -OutFile $OutFile
        }
        catch {
            Write-Host "Could not download file from URL: $File" -ForegroundColor Red
            break
        }
        $File = $OutFile
        if (!(Test-Path $File)) {
            Write-Host "$File could not be located." -ForegroundColor Red
            break
        }
    }
    elseif ($URL -eq $false) {
        if (!(Test-Path $File)) {
            Write-Host "$File could not be located." -ForegroundColor Red
            break
        }
        $FileName = Get-Item $File | Select-Object -ExpandProperty Name
    }
    $B64File = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$File"));

    if ($URL -eq $true) {
        Remove-Item $File -Force
    }

    $JSON = @"
{
    "@odata.type": "#microsoft.graph.deviceManagementScript",
    "displayName": "$FileName",
    "description": "$Description",
    "runSchedule": {
    "@odata.type": "microsoft.graph.runSchedule"
},
    "scriptContent": "$B64File",
    "runAsAccount": "system",
    "enforceSignatureCheck": "false",
    "fileName": "$FileName"
}
"@

    $graphApiVersion = "Beta"
    $DMS_resource = "deviceManagement/deviceManagementScripts"
    Write-Verbose "Resource: $DMS_resource"

    try {
        $uri = "https://graph.microsoft.com/$graphApiVersion/$DMS_resource"
        #Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
        Invoke-RestMethod -Uri $uri -Headers @{Authorization = "Bearer $($token)"} -Method Post -Body $JSON -ContentType "application/json"
    }

    catch {

        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break

    }

}

####################################################

$Configurations = Get-ChildItem -Path .\Config\ps\
#$FilePS = "HardenMDE - Disable Flash on AdobeReaderDC"
$Location = $(Get-Location).Path

foreach($Configuration in $Configurations){
$FileName = $Configuration.Name
write-host $FileName
Add-DeviceManagementScript -File $Location\Config\ps\$FileName -Description "$FileName v1.0"
}
