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
    'Harden365.Audit-ExchangeOnline'
    'Harden365.AuditApplications'
    'Harden365.ExchangeOnline'
    'Harden365.DefenderForO365'
    'Harden365.DKIM'
    'Harden365.TierModel'
    'Harden365.CA'
    'Harden365.ExportForCA'
    'Harden365.MFAperUser'
    'Harden365.ImportPhoneNumbers'
    'Harden365.PowerPlatform'
    'Harden365.Teams'
    'Harden365.Sharepoint'
    'Harden365.Outlook'
    'Harden365.HardenApp'
    'Harden365.DeviceSecurityImport'
    'Harden365.DeviceADMXImport'
    'Harden365.DeviceScriptImport'
    'Harden365.DeviceCatalogImport'
    'Harden365.DeviceConfigImport'
    'Harden365.Identity.Roles'
    'Harden365.Identity.Users'
    'Harden365.Identity.Applications'
)

function Test-UserIsAdministrator {
    
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (!$isAdmin) {
        Write-LogError 'You must run this script as an administrator to update or install powershell module'
        Write-LogError 'Script execution cancelled'
        Pause; Break
    }
}

function Test-PowerShellModule {
    param(
        [Array]$installedModule,
        [String]$ModuleName,
        [String]$ModuleVersion,
        [int]$OperationCount,
        [int]$OperationTotal
    )

    Update-ProgressionBarInnerLoop -Activity "Check $ModuleName Powershell module" -Status 'In progress' -OperationCount $OperationCount -OperationTotal $OperationTotal

    $installedCheckModule = $installedModule | where-object {$_.Name -eq $ModuleName}

        if (!$installedCheckModule) {
            Write-LogWarning "$ModuleName Powershell Module necessary"
            Test-UserIsAdministrator
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
            Write-LogInfo ("Installing $ModuleName Powershell Module")
            Install-Module $ModuleName -AllowClobber
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Untrusted
        }
        elseif ([System.Version]$installedCheckModule.Version -lt [System.Version]$ModuleVersion) {
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
    $numberOfPrerequisitesCheck = 9
    $currentCountOfPrerequisitesCheck = 0

    Update-ProgressionBarOuterLoop -Activity 'Prerequisites check' -Status 'In progress' -OperationCount $OperationCount -OperationTotal $OperationTotal
    
    Update-ProgressionBarInnerLoop -Activity 'Check PowerShell version' -Status 'In progress' -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    
    $installedModule = Get-InstalledModule

    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'ExchangeOnlineManagement' -ModuleVersion '2.0.5' -installedModule $installedModule  -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'MSOnline' -ModuleVersion '1.1' -installedModule $installedModule -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'Microsoft.Online.SharePoint.PowerShell' -ModuleVersion '16.0' -installedModule $installedModule -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'Microsoft.PowerApps.Administration.PowerShell' -ModuleVersion '2.0.147' -installedModule $installedModule -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'Microsoft.PowerApps.PowerShell' -ModuleVersion '1.0.20' -installedModule $installedModule -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++ 
    Test-PowerShellModule -ModuleName 'MSCommerce' -ModuleVersion '1.10' -installedModule $installedModule -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'MicrosoftTeams' -ModuleVersion '4.2.0' -installedModule $installedModule -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
    $currentCountOfPrerequisitesCheck++
    Test-PowerShellModule -ModuleName 'ORCA' -ModuleVersion '2.8.1' -installedModule $installedModule -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck
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
    $allModulesPathList | ForEach-Object {
        Import-ScriptModule ".\Mod\$_.psm1" -OperationCount $currentCountOfModules -OperationTotal $numberOfModules
        $currentCountOfModules++
    }
    Update-ProgressionBarInnerLoop -Activity 'Script modules load' -Status 'Complete' -OperationCount $currentCountOfPrerequisitesCheck -OperationTotal $numberOfPrerequisitesCheck

    $OperationCount = 2
    Update-ProgressionBarOuterLoop -Activity 'Prerequisites check' -Status 'Complete' -OperationCount $OperationCount -OperationTotal $OperationTotal

    Write-LogSection '' -NoHostOutput
}

function Remove-AllHarden365Modules {
    $allModulesPathList | ForEach-Object {
        Remove-Module $_ -ErrorAction SilentlyContinue
    }
}
