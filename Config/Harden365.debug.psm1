<# 
    .NOTES
    ===========================================================================
        FileName:     debug.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 11/26/2021
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Protect your data in minutes

    .DESCRIPTION
        load debug function using in Harden 365 project
#>


$dateFileString = Get-Date -Format 'FileDateTimeUniversal'

$debugFolderPath = Join-Path $pwd 'Logs'

if (!(Test-Path -Path $debugFolderPath)) {
    New-Item -Path $pwd -Name 'Logs' -ItemType Directory > $null
}

$debugFileFullPath = Join-Path $debugFolderPath "Debug$dateFileString.log"

New-Item -Path $debugFileFullPath -ItemType File > $null

function Update-ProgressionBarOuterLoop {
    param(
        [String]$Activity,
        [String]$Status,
        [int]$OperationCount,
        [int]$OperationTotal
    )
    if ($OperationCount -eq $OperationTotal) {
        Write-Progress -Activity $Activity -Status "$Status : Complete" -Complete
    } else {
        $perventageComplete = [math]::Round( ($OperationCount * 100) / $OperationTotal, 3)
        Write-Progress -Activity $Activity -Status "$Status : $perventageComplete%" -PercentComplete $perventageComplete 
    }
}

function Update-ProgressionBarInnerLoop {
    param(
        [String]$Activity,
        [String]$Status,
        [int]$OperationCount,
        [int]$OperationTotal
    )

    if ($OperationCount -eq $OperationTotal) {
        Write-Progress -Id 1 -Activity $Activity -Status "$Status : Complete" -Complete
    } else {
        $perventageComplete = [math]::Round( ($OperationCount * 100) / $OperationTotal, 3)
        Write-Progress -Id 1 -Activity $Activity -Status "$Status : $perventageComplete%" -PercentComplete $perventageComplete 
    }
}

function Write-LogSection {
    param(
        [Parameter(Mandatory = $false)]
        [String]$Text,
        [switch]$NoHostOutput
    )

    Write-LogInternal -Text $Text -InfoType '****'
}

function Write-LogInfo {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Text,
        [switch]$NoHostOutput
    )

    if (!$NoHostOutput) {
        write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
        Write-Host $Text -ForegroundColor Green
    }
    Write-LogInternal -Text $Text -InfoType '---> INFO:'
}

function Write-LogWarning {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Text,
        [switch]$NoHostOutput
    )
    if (!$NoHostOutput) {
        write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
        Write-Warning $Text
    }
    Write-LogInternal -Text $Text -InfoType '---! WARNING:'
}

function Write-LogError {
    param(
        [Parameter(Mandatory = $true)]
        [String]$Text,
        [switch]$NoHostOutput
    )
    if (!$NoHostOutput) {
        write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
        Write-Error $Text
    }
    Write-LogInternal -Text $Text -InfoType '---! ERROR:'
}

function Write-LogInternal {
    param(
        [Parameter(Mandatory = $false)]
        [String]$Text,
        [Parameter(Mandatory = $true)]
        [String]$InfoType
        )
    "$(Get-Date -UFormat "%m-%d-%Y %T ") $InfoType $Text" | Out-File "$debugFileFullPath" -Append
}
