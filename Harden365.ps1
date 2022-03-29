<# 
    .NOTES
    ===========================================================================
        FileName:     harden365.ps1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 11/29/2021
        Version:      v0.7
    ===========================================================================

    .DESCRIPTION
        Protect your data in minutes

    .DEPENDENCIES
        PowerShell 5.1
        Security Default disable

    .UPDATES
    0.7 - 11/27/2021
        Rewrite debug system
    0.6 - 11/26/2021
        Rewrite prerequisites
    0.5 - 11/02/2021
        Add notes
    0.4 - 09/28/2021
        Add Menu


#>


param(
    [Parameter(Mandatory = $false)]
    [switch]$reloadModules
)

$totalCountofOperations = 2
$currentCountOfOperations = 0

clear-Host
(0..10)| % {write-host }

if ($reloadModules) {
    Remove-Module 'Harden365.debug'
    Remove-Module 'Harden365.prerequisites'
}

write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
Write-Host("LOADING HARDEN 365") -ForegroundColor Red
Import-Module '.\config\Harden365.debug.psm1'
Import-Module '.\config\Harden365.prerequisites.psm1'
if ($reloadModules) {
    Remove-AllHarden365Modules
}

## PREREQUISITES
Test-AllPrerequisites -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$currentCountOfOperations++
Import-AllScriptModules -OperationCount $currentCountOfOperations -OperationTotal $totalCountofOperations
$currentCountOfOperations++


start-sleep -Seconds 2


## MENU
$LogoData = Get-Content (".\Config\Harden365.logo")
$FrontStyle = "
            _________________________________________________________________________________________
            "
$EndStyle = "_________________________________________________________________________________________
            
            Please select an option"

function MainMenu(){
    clear
    foreach ($line in $LogoData){Write-Host $line}
    Write-Host "            HARDEN 365 - MENU" -ForegroundColor Red
    switch(
        Read-Host "$FrontStyle
            A.  Audit tenant
            H.  Hardening tenant
            S.  Settings
            Q.  to Quit
            $EndStyle")
            {
                Q {break}
                A {AuditMenu}
                H {HardenMenu}
                default {"N/A"}
    }
}

function AuditMenu(){
    clear
    foreach ($line in $LogoData){Write-Host $line}
    Write-Host "            AUDIT" -ForegroundColor Red
        switch(
           Read-Host "$FrontStyle
            1.  Audit Microsoft Defender for O365 with ORCA
            2.  Audit Administration Roles
            3.  Audit Users with licenses
            R.  Return to Main Menu
            $EndStyle")
            {
             R {MainMenu}
             1 {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-Host "AUDIT TENANT With ORCA"-ForegroundColor Green	
                Invoke-ORCA -Output HTML -OutputDirectory .\Audit\
                Read-Host -Prompt "Press Enter to return_"
                AuditMenu
                }
             2 {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("AUDIT ADMINISTRATION ROLES") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to Azure AD Powershell') -ForegroundColor Green
                try {
                Get-AzureADTenantDetail | Out-Null 
                } catch {Connect-AzureAD | Out-Null} 

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Get-AADRolesAudit'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                AuditMenu
                }
             3 {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("AUDIT USERS WITH LICENCES") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to  MSOL Service') -ForegroundColor Green
                Connect-MsolService | Out-Null

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Get-MSOAuditUsers'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                AuditMenu
                }
             default {"N/A"}
    }
}

function HardenMenu(){
    clear
    foreach ($line in $LogoData){Write-Host $line}
    Write-Host "            HARDENING" -ForegroundColor Red
        switch(
           Read-Host "$FrontStyle
            1.  Microsoft Defender for O365
            2.  Identity
            R.  Return to Main Menu
            $EndStyle")
            {
             R {MainMenu}
             1 {DefForO365Menu}
             2 {IdentityMenu}
             default {"N/A"}
    }
}

function DefForO365Menu(){
    clear
    foreach ($line in $LogoData){Write-Host $line}
    Write-Host "            HARDENING - MICROSOFT DEFENDER FOR OFFICE 365" -ForegroundColor Red
        switch(
           Read-Host "$FrontStyle
            1.  Microsoft Defender for Office 365
            2.  Exchange Online Protection Only
            3.  SPF/DKIM/DMARC - Audit and Configuration
            4.  Advanced Settings
            R.  Return to Main Menu
            $EndStyle")
            {
             R {HardenMenu}
             1 {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
             write-host("HARDENING MICROSOFT DEFENDER FOR O365") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
             Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
             try {Get-OrganizationConfig | Out-Null 
             } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}


             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ExchangeOnline'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
             write-host("ERROR --> Harden365.ExchangeOnline module not working") -ForegroundColor Red}
             }

             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.DefenderForO365'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
             write-host("ERROR --> Harden365.DefenderForO365 module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             DefForO365Menu
            }
             2 {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
             write-host(" HARDENING EXCHANGE ONLINE PROTECTION") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
             Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
             try {Get-OrganizationConfig | Out-Null 
             } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}


             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ExchangeOnline'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
             write-host("ERROR --> Harden365.ExchangeOnline module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             DefForO365Menu
            }
            3 {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
             write-host("SPF/DKIM/DMARC - AUDIT AND CONFIGURATION") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
             Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
             Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false


             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.DKIM'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
             write-host("ERROR --> Harden365.DKIM module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             DefForO365Menu
            }
            default {"N/A"}
            }
}

function IdentityMenu(){
    clear
    foreach ($line in $LogoData){Write-Host $line}
    Write-Host "            HARDENING IDENTITY" -ForegroundColor Red
        switch(
           Read-Host "$FrontStyle
            1.  Tier Model
            2.  Conditional Access / MFA
            3.  Advanced Settings
            R.  Return to Main Menu
            $EndStyle")
            {
             R {HardenMenu}
             1 {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
                write-host("HARDENING TIER MODEL") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
                Write-host ('Connecting to Azure AD Powershell') -ForegroundColor Green
                Connect-AzureAD -WarningAction:SilentlyContinue
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
                Write-host ('Connecting to  MSOL Service') -ForegroundColor Green
                Connect-MsolService | Out-Null
	
                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.TierModel'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                } Catch {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
                write-host(" --> Harden365.TierModel module not working") -ForegroundColor Red}
                }
                Read-Host -Prompt "Press Enter to return_"
                IdentityMenu
                }
             2 {MFACondAcc}
             default {"N/A"}
    }
}

function MFACondAcc(){
    clear
    foreach ($line in $LogoData){Write-Host $line}
    Write-Host "            HARDENING - CONFIGURE MFA" -ForegroundColor Red
        switch(
           Read-Host "$FrontStyle
            1.  Enable MFA per User
            2.  Conditional Access / MFA
            3.  Export Users in CSV
            4.  Import PhoneNumbers by CSV
            R.  Return to Main Menu
            $EndStyle")
            {
             R {IdentityMenu}
             1 {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
                write-host("HARDENING ENABLE MFA PER USER") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
                Write-host ('Connecting to  MSOL Service') -ForegroundColor Green
                Connect-MsolService | Out-Null

               $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.MFAperUser'})
               $scriptFunctions | ForEach-Object {
               Try { 
               & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
               } Catch {
               write-host(" --> Harden365.MFAperUser module not working") -ForegroundColor Red}
               }
               Read-Host -Prompt "Press Enter to return_"
               MFACondAcc
               }
             2 {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
                write-host("HARDENING ENABLE MFA WITH CONDITIONNAL ACCESS") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
                Write-host ('Connecting to  AzureAD') -ForegroundColor Green
                try {
                Get-AzureADTenantDetail | Out-Null 
                } catch {Connect-AzureAD | Out-Null} 

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.CA'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
                } Catch {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
                write-host(" --> Harden365.CA module not working") -ForegroundColor Red}
                }
                Read-Host -Prompt "Press Enter to return_"
                MFACondAcc
                }
              3 {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
                write-host("HARDENING EXPORT PHONENUMBERS IN CSV") -ForegroundColor Red
                Connect-MsolService | Out-Null

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.CAExport'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                MFACondAcc
                }
              4 {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline
                write-host("HARDENING IMPORT PHONENUMBERS BY CSV") -ForegroundColor Red

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ImportPhoneNumbers'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                MFACondAcc
                }
              default {"N/A"}
              }
}

## RUN MAIN MENU
MainMenu
