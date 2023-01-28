﻿<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.DeviceCatalogImport.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   06/15/2022
        Last Updated: 06/15/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Export to JSON Device configuration setting

    .DESCRIPTION

#>

Function Start-CatalogSettingsImport {
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

    Write-LogSection 'CONFIGURATION POLICIES IMPORT' -NoHostOutput


    #region Authentification
    $ApplicationID = $(Get-AzureADApplication -Filter "DisplayName eq 'Harden365 App'").AppId
    $TenantDomainName = $(Get-AzureADTenantDetail).ObjectId

    $Body = @{
        Grant_Type    = 'client_credentials'
        Scope         = 'https://graph.microsoft.com/.default'
        client_Id     = $ApplicationID
        Client_Secret = $AccessSecret
    }
    $ConnectGraph = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantDomainName/oauth2/v2.0/token -Method POST -Body $Body
    $token = $ConnectGraph.access_token
    #endregion

    $graphApiVersion = 'Beta'
    $ESP_resource = 'deviceManagement/configurationPolicies'
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($ESP_resource)"
    


    $Configurations = Get-ChildItem -Path .\Config\json\CatalogSettings\

    foreach ($Configuration in $Configurations) {
        $FileName = $Configuration.Name
        write-LogInfo "Adding Device Catalog '$FileName'"
        $JSON_Data = Get-Content -Path ".\Config\json\CatalogSettings\$FileName"
        $JSON_Convert = $JSON_Data | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version, supportsScopeTags
        $JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 20

        #region CONNECT GRAPH
        Invoke-RestMethod -Uri $uri -Headers @{Authorization = "Bearer $($token)" } -Method Post -Body $JSON_Output -ContentType 'application/json'
        #endregion

    }
}