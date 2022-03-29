<#
.DESCRIPTION
    All audit function requesting based on SharePoint Online module
.NOTES
    Author:       Community Harden - contact@harden365.net
    Created On:   09/28/2021
    Last Updated: 11/26/2021
    Version:      v0.5
#>

<#
.DESCRIPTION
    Export all SharePoint Online site collections infos in CSV file
.NOTES
    SPO PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-SPOSitesCollectionCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-SPOSitesCollectionCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all SP site collections'
    
    $allSPOSites = Get-SPOSite -Limit All

    Write-LogInfo "$($allSPOSites.Count) site collections found"
    
    $exportFullPath = "$pwd\Audit\$ExportName\SPOSitesCollection-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $allSPOSites | Select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $allSPOSites
}

<#
.DESCRIPTION
    Export all individual OneDrives infos in CSV file
.NOTES
    SPO PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-SPOOneDrivesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-SPOOneDrivesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all OneDrives '
    
    $allO4BSites = Get-SPOSite -Template "SPSPERS" -limit ALL -includepersonalsite $True

    Write-LogInfo "$($allO4BSites.Count) onedrives found"
    
    $exportFullPath = "$pwd\Audit\$ExportName\SPOOneDrives-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $allO4BSites | Select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $allO4BSites
}

<#
.DESCRIPTION
    Export all individual OneDrives infos in CSV file
.NOTES
    SPO PowerShell Module required
.PARAMETER ExportName
    Used in CSV export name (use company/tenant name)
.PARAMETER DateFileString
    Date Identifier
.EXAMPLE
    Get-SPOOneDrivesCSVExport -ExportName 'Contoso' -DateFileString '20211126T2043176618Z'
#>
function Get-SPOOneDrivesCSVExport {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName,
        [Parameter(Mandatory = $true)]
        [String]$DateFileString
    )

    Write-LogInfo 'Request all OneDrives '
    
    $allO4BSites = Get-SPOSite -Template "SPSPERS" -limit ALL -includepersonalsite $True

    Write-LogInfo "$($allO4BSites.Count) onedrives found"
    
    $exportFullPath = "$pwd\Audit\$ExportName\SPOOneDrives-$ExportName-$DateFileString.csv"
    Write-LogInfo "Export to CSV at $exportFullPath"
    $allO4BSites | Select * | Export-Csv -Path $exportFullPath -Delimiter ';' -Encoding UTF8 -NoTypeInformation

    $allO4BSites
}