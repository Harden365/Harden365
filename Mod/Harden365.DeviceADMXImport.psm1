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

Function Start-DeviceADMXImport {
     <#
        .Synopsis
         DeviceScriptImport
        
        .Description
         This function will 

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
)

Write-LogSection 'DEVICE ADMX IMPORT' -NoHostOutput

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



function import-ADMX
{



	Param (
		
		[Parameter(Mandatory = $true)]
		[string]$ImportPath
		
	)
	

	####################################################>
	
	Function Create-GroupPolicyConfigurations()
	{
		
<#
.SYNOPSIS
This function is used to add an device configuration policy using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a device configuration policy
.EXAMPLE
Add-DeviceConfigurationPolicy -JSON $JSON
Adds a device configuration policy in Intune
.NOTES
NAME: Add-DeviceConfigurationPolicy
#>
		
		[cmdletbinding()]
		param
		(
			$DisplayName
		)
		
		$jsonCode = @"
{
    "description":"",
    "displayName":"$($DisplayName)"
}
"@
		
		$graphApiVersion = "Beta"
		$DCP_resource = "deviceManagement/groupPolicyConfigurations"
		
		try
		{
			
			$uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
			$responseBody = Invoke-RestMethod -Uri $uri -Headers @{Authorization = "Bearer $($token)"} -Method Post -Body $jsonCode -ContentType "application/json"

		
			
		}
		
		catch
		{
			
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
		$responseBody.id
	}
	
	
	Function Create-GroupPolicyConfigurationsDefinitionValues()
	{
		
    <#
    .SYNOPSIS
    This function is used to get device configuration policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any device configuration policies
    .EXAMPLE
    Get-DeviceConfigurationPolicy
    Returns any device configuration policies configured in Intune
    .NOTES
    NAME: Get-GroupPolicyConfigurations
    #>
		
		[cmdletbinding()]
		Param (
			
			[string]$GroupPolicyConfigurationID,
			$JSON
			
		)
		
		$graphApiVersion = "Beta"
		
		$DCP_resource = "deviceManagement/groupPolicyConfigurations/$($GroupPolicyConfigurationID)/definitionValues"
		try
		{
			if ($JSON -eq "" -or $JSON -eq $null)
			{
				
				write-host "No JSON specified, please specify valid JSON for the Device Configuration Policy..." -f Red
				
			}
			
			else
			{
				
				Test-JSON -JSON $JSON
				
				$uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
                Invoke-RestMethod -Uri $uri -Headers @{Authorization = "Bearer $($token)"} -Method Post -Body $JSON -ContentType "application/json"
			}
			
		}
		
		catch
		{
			
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
	
	Function Test-JSON()
	{
		
<#
.SYNOPSIS
This function is used to test if the JSON passed to a REST Post request is valid
.DESCRIPTION
The function tests if the JSON passed to the REST Post is valid
.EXAMPLE
Test-JSON -JSON $JSON
Test if the JSON is valid before calling the Graph REST interface
.NOTES
NAME: Test-AuthHeader
#>
		
		param (
			
			$JSON
			
		)
		
		try
		{
			
			$TestJSON = ConvertFrom-Json $JSON -ErrorAction Stop
			$validJson = $true
			
		}
		
		catch
		{
			
			$validJson = $false
			$_.Exception
			
		}
		
		if (!$validJson)
		{
			
			Write-Host "Provided JSON isn't in valid JSON format" -f Red
			break
			
		}
		
	}
	
#################################################
	
	$ImportPath = $ImportPath.replace('"', '')
	
	if (!(Test-Path "$ImportPath"))
	{
		
		Write-Host "Import Path doesn't exist..." -ForegroundColor Red
		Write-Host "Script can't continue..." -ForegroundColor Red
		break
		
	}
	$PolicyName = (Get-Item $ImportPath).Name
	Write-Host "Adding ADMX Configuration Policy '$PolicyName'" -ForegroundColor Green
	$GroupPolicyConfigurationID = Create-GroupPolicyConfigurations -DisplayName $PolicyName
	
	$JsonFiles = Get-ChildItem $ImportPath
	
	foreach ($JsonFile in $JsonFiles)
	{
		
		$JSON_Data = Get-Content "$($JsonFile.FullName)"
		
		# Excluding entries that are not required - id,createdDateTime,lastModifiedDateTime,version
		$JSON_Convert = $JSON_Data | ConvertFrom-Json | Select-Object -Property * -ExcludeProperty id, createdDateTime, lastModifiedDateTime, version, supportsScopeTags
		$JSON_Output = $JSON_Convert | ConvertTo-Json -Depth 5
		Create-GroupPolicyConfigurationsDefinitionValues -JSON $JSON_Output -GroupPolicyConfigurationID $GroupPolicyConfigurationID

	}

}


$ImportPath =".\Config\json\ADMXConfig"
Get-ChildItem "$ImportPath" | Where-Object { $_.PSIsContainer -eq $True } | ForEach-Object { import-ADMX $_.FullName }
}