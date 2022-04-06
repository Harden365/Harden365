<# 
    .NOTES
    ===========================================================================
        FileName:     Prerequisites.ps1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 11/26/2021
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Protect your data in minutes

    .DESCRIPTION
        Check and install Powershell Modules
        Load Script Modules
#>

$allModulesPathList = @(
    'Harden365.ConnectAllM365Services'
    'Harden365.AzureADAudit'
    'Harden365.EXOAudit'
    'Harden365.MSOLAudit'
    'Harden365.SPOAudit'
    'Harden365.ExchangeOnline'
    'Harden365.DefenderForO365'
    'Harden365.DKIM'
    'Harden365.TierModel'
    'Harden365.CA'
    'Harden365.CAExport'
    'Harden365.MFAperUser'
    'Harden365.ImportPhoneNumbers'
    'Get-AADRolesAudit'
    'Get-MSOAuditUsers'


)

function Add-AuditFolder {
    param(
        [Parameter(Mandatory = $true)]
        [String]$ExportName
    )
    $auditPath = Join-Path $pwd 'Audit'
    if (!(Test-Path -Path $auditPath)) {
        New-Item -Path $pwd -Name 'Audit' -ItemType Directory > $null
    }

    $auditFullPath = Join-Path $auditPath $ExportName
    if (!(Test-Path -Path $auditFullPath)) {
        New-Item -Path $auditPath -Name $ExportName -ItemType Directory > $null
    }
}

function Test-UserIsAdministrator {
    
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$isAdmin) {
        Write-LogError 'You must run this script as an administrator to update or install powershell module'
        Write-LogError 'Script execution cancelled'
        Pause;Break
    }
}

function Test-PowerShellModule {
    param(
        [String]$ModuleName,
        [String]$ModuleVersion,
        [int]$OperationCount,
        [int]$OperationTotal
    )

    Update-ProgressionBarInnerLoop -Activity "Check $ModuleName Powershell module" -Status 'In progress' -OperationCount $OperationCount -OperationTotal $OperationTotal

    $installedPSModule = Get-InstalledModule $ModuleName -ErrorAction Ignore
    $installedPSModuleVersion = Get-InstalledModule $ModuleName -MinimumVersion $ModuleVersion -ErrorAction Ignore
    if($installedPSModule -eq $null){
        Write-LogInfo ("Installing $ModuleName Powershell Module")
        Check-UserIsAdministrator
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Install-Module $ModuleName -AllowClobber
        Write-LogWarning "$ModuleName Powershell Module necessary"
    } elseif ($installedPSModuleVersion -eq $null) {
        Write-LogInfo ("Updating $ModuleName Powershell Module")
        Test-UserIsAdministrator
        Pause
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Update-Module $ModuleName 
        Write-LogInfo "$ModuleName Powershell Module updated"
    }
    Write-LogInfo "$ModuleName Powershell Module installed"
}

function Test-AllPrerequisites {
    param(
        [int]$OperationCount,
        [int]$OperationTotal
    )
    Write-LogSection 'PREREQUISITES' -NoHostOutput
    $numberOfPrerequisitesCheck = 7
    $currentCountOfPrerequisitesCheck = 0

    Update-ProgressionBarOuterLoop -Activity 'Prerequisites check' -Status 'In progress' -OperationCount $OperationCount -OperationTotal $OperationTotal
    
    Update-ProgressionBarInnerLoop -Activity 'Check PowerShell version' -Status 'In progress' -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck

    if(($PSVersionTable.PSVersion.Major -lt 5) -or ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -eq 0)){
        Write-LogError 'Please install Powershell version 5.1'
        Write-LogError 'https://www.microsoft.com/en-us/download/details.aspx?id=54616'
        break Script
    } else {
        Write-LogInfo 'Powershell Version OK'
    }

    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'ExchangeOnlineManagement' -ModuleVersion '2.0' -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'AzureADPreview' -ModuleVersion '2.0' -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'MSOnline' -ModuleVersion '1.1' -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'Microsoft.Online.SharePoint.PowerShell' -ModuleVersion '16.0' -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'MicrosoftTeams' -ModuleVersion '2.6' -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'ORCA' -ModuleVersion '2.0' -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++
    Update-ProgressionBarInnerLoop -Activity 'Prerequisite check' -Status 'Complete' -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck

    Write-LogInfo 'All prerequisites loaded'
    Write-LogSection '' -NoHostOutput
}

function Import-ScriptModule {
    param(
        [int]$OperationCount,
        [int]$OperationTotal,
        [String]$ModulePath
    )

    Update-ProgressionBarInnerLoop -Activity "Load $ModulePath module" -Status 'In progress' -OperationCount $OperationCount -OperationTotal $OperationTotal

    Import-Module $ModulePath -Scope Global
    Write-LogInfo "$ModulePath loaded"
}

function Import-AllScriptModules {
    param(
        [int]$OperationCount,
        [int]$OperationTotal
    )
    Write-LogSection 'MODULES' -NoHostOutput
    $numberOfModules = $allModulesPathList.Count
    $currentCountOfModules = 0

    Update-ProgressionBarOuterLoop -Activity 'Prerequisites check' -Status 'In progress' -OperationCount $OperationCount -OperationTotal $OperationTotal

    Update-ProgressionBarInnerLoop -Activity 'Script modules load' -Status 'In progress' -OperationCount $currentCountOfModules -OperationTotal $numberOfModules
    $allModulesPathList | % {
        Import-ScriptModule ".\Mod\$_.psm1" -OperationCount $currentCountOfModules -OperationTotal $numberOfModules
        $currentCountOfModules++
    }
    Update-ProgressionBarInnerLoop -Activity 'Script modules load' -Status 'Complete' -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck

    $OperationCount = 2
    Update-ProgressionBarOuterLoop -Activity 'Prerequisites check' -Status 'Complete' -OperationCount $OperationCount -OperationTotal $OperationTotal

    Write-LogSection '' -NoHostOutput
}

function Remove-AllHarden365Modules {
    $allModulesPathList | % {
        Remove-Module $_ -ErrorAction SilentlyContinue
    }
}
