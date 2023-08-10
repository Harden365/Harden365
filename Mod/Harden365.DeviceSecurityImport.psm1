<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.DeviceADMXImport.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   06/15/2022
        Last Updated: 06/15/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Export to Device ADMX setting

    .DESCRIPTION

#>

Function Start-DeviceSecurityImport {
     <#
        .Synopsis
         DeviceScriptImport
        
        .Description
         This function will 

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
    [String]$AccessSecret
)

Write-LogSection 'DEVICE SECURITY IMPORT' -NoHostOutput

#region Authentification
$ApplicationID = $(Get-MgApplication -Filter "DisplayName eq 'Harden365 App'").AppId
$TenantDomainName = $(Get-MgContext).TenantId


$Body = @{
Grant_Type    = "client_credentials"
Scope         = "https://graph.microsoft.com/.default"
client_Id     = $ApplicationID
Client_Secret = $AccessSecret
}
$ConnectGraph = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantDomainName/oauth2/v2.0/token -Method POST -Body $Body
$token = $ConnectGraph.access_token
#endregion


Function Get-EndpointSecurityTemplate(){

<#
.SYNOPSIS
This function is used to get all Endpoint Security templates using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets all Endpoint Security templates
.EXAMPLE
Get-EndpointSecurityTemplate 
Gets all Endpoint Security Templates in Endpoint Manager
.NOTES
NAME: Get-EndpointSecurityTemplate
#>


$graphApiVersion = "Beta"
$ESP_resource = "deviceManagement/templates?`$filter=(isof(%27microsoft.graph.securityBaselineTemplate%27))"

    try {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($ESP_resource)"
        #(Invoke-RestMethod -Method Get -Uri $uri -Headers $authToken).value
        (Invoke-RestMethod -Uri $uri -Headers @{Authorization = "Bearer $($token)"} -Method Get).Value

    }
    
    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-LogError "Response content:`n$responseBody"
    Write-LogError "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    break

    }

}

####################################################

Function Add-EndpointSecurityPolicy(){

<#
.SYNOPSIS
This function is used to add an Endpoint Security policy using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds an Endpoint Security  policy
.EXAMPLE
Add-EndpointSecurityDiskEncryptionPolicy -JSON $JSON -TemplateId $templateId
Adds an Endpoint Security Policy in Endpoint Manager
.NOTES
NAME: Add-EndpointSecurityPolicy
#>

[cmdletbinding()]

param
(
    $TemplateId,
    $JSON
)

$graphApiVersion = "Beta"
$ESP_resource = "deviceManagement/templates/$TemplateId/createInstance"

    try {

        if($JSON -eq "" -or $JSON -eq $null){

        Write-LogError "No JSON specified, please specify valid JSON for the Endpoint Security Policy..."

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($ESP_resource)"
        #Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
        Invoke-RestMethod -Uri $uri -Headers @{Authorization = "Bearer $($token)"} -Method Post -Body $JSON -ContentType "application/json"

        }

    }
    
    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-LogError "Response content:`n$responseBody"
    Write-LogError "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    break

    }

}


####################################################

$Configurations = Get-ChildItem -Path .\Config\json\EndpointSecurity\

foreach($Configuration in $Configurations){
    $FileName = $Configuration.Name

###################################################

# Getting content of JSON Import file
$JSON_Data = Get-Content -Path ".\Config\json\EndpointSecurity\$FileName"

# Converting input to JSON format
$JSON_Convert = $JSON_Data | ConvertFrom-Json

# Pulling out variables to use in the import
$JSON_DN = $JSON_Convert.displayName
$JSON_TemplateDisplayName = $JSON_Convert.TemplateDisplayName
$JSON_TemplateId = $JSON_Convert.templateId


####################################################

# Get all Endpoint Security Templates
$Templates = Get-EndpointSecurityTemplate

####################################################

# Checking if templateId from JSON is a valid templateId
$ES_Template = $Templates | ?  { $_.id -eq $JSON_TemplateId }

####################################################

# If template is a baseline Edge, MDATP or Windows, use templateId specified
if(($ES_Template.templateType -eq "microsoftEdgeSecurityBaseline") -or ($ES_Template.templateType -eq "securityBaseline") -or ($ES_Template.templateType -eq "advancedThreatProtectionSecurityBaseline")){

    $TemplateId = $JSON_Convert.templateId

}

####################################################

# Else If not a baseline, check if template is deprecated
elseif($ES_Template){

    # if template isn't deprecated use templateId
    if($ES_Template.isDeprecated -eq $false){

        $TemplateId = $JSON_Convert.templateId

    }

    # If template deprecated, look for lastest version
    elseif($ES_Template.isDeprecated -eq $true) {

        $Template = $Templates | ? { $_.displayName -eq "$JSON_TemplateDisplayName" }

        $Template = $Template | ? { $_.isDeprecated -eq $false }

        $TemplateId = $Template.id

    }

}

####################################################

# Else If Imported JSON template ID can't be found check if Template Display Name can be used
elseif($ES_Template -eq $null){

    Write-LogError "Didn't find Template with ID $JSON_TemplateId, checking if Template DisplayName '$JSON_TemplateDisplayName' can be used..."
    $ES_Template = $Templates | ?  { $_.displayName -eq "$JSON_TemplateDisplayName" }

    If($ES_Template){

        if(($ES_Template.templateType -eq "securityBaseline") -or ($ES_Template.templateType -eq "advancedThreatProtectionSecurityBaseline")){

            Write-LogError "TemplateID '$JSON_TemplateId' with template Name '$JSON_TemplateDisplayName' doesn't exist..."
            Write-LogError "Importing using the updated template could fail as settings specified may not be included in the latest template..."
            break

        }

        else {

            Write-LogInfo "Template with displayName '$JSON_TemplateDisplayName' found..."

            $Template = $ES_Template | ? { $_.isDeprecated -eq $false }

            $TemplateId = $Template.id

        }

    }

    else {

        Write-LogError "TemplateID '$JSON_TemplateId' with template Name '$JSON_TemplateDisplayName' doesn't exist..."
        Write-LogError "Importing using the updated template could fail as settings specified may not be included in the latest template..."
        break

    }

}

####################################################

# Excluding certain properties from JSON that aren't required for import
$JSON_Convert = $JSON_Convert | Select-Object -Property * -ExcludeProperty TemplateDisplayName,TemplateId,versionInfo

$DisplayName = $JSON_Convert.displayName

$JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5

Write-LogInfo "Adding Device Security '$DisplayName'"
Add-EndpointSecurityPolicy -TemplateId $TemplateId -JSON $JSON_Output
}
}