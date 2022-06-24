$FrontStyle = "
            _________________________________________________________________________________________
            
            "
Function CreateMenu (){
    
    Param(
        [Parameter(Mandatory=$False)]
        [String]$MenuTitle,
        [String]$TenantEdition,
        [String]$O365ATP,
        [Boolean]$TenantDetail = $false,
        [Parameter(Mandatory=$True)][array]$MenuOptions
    )

    $MaxValue = $MenuOptions.count-1
    $Selection = 0
    $EnterPressed = $False

$FrontStyle = "    _________________________________________________________________________________________            
            "
    
    Clear-Host

    While($EnterPressed -eq $False){
    $LogoData = Get-Content (".\Config\Harden365.logo")
        foreach ($line in $LogoData){Write-Host $line}
 
        Write-Host "    $MenuTitle" -ForegroundColor Red
        Write-Host $FrontStyle -ForegroundColor Red

    if ($TenantDetail -eq $True) {
        write-Host "    AzureAD Edition = " -NoNewline -ForegroundColor Red
        write-Host "$TenantEdition"
        write-Host "    DefenderO365 Edition = " -NoNewline -ForegroundColor Red
        write-Host "$O365ATP"
        Write-Host $FrontStyle -ForegroundColor Red
    }
        For ($i=0; $i -le $MaxValue; $i++){
            
            If ($i -eq $Selection){
                Write-Host -NoNewline "    "
                Write-Host -BackgroundColor yellow -ForegroundColor Black "[ $($MenuOptions[$i]) ]"
            } Else {
                Write-Host "      $($MenuOptions[$i])  "
            }

        }

        $KeyInput = $host.ui.rawui.readkey("NoEcho,IncludeKeyDown").virtualkeycode

        Switch($KeyInput){
            13{
                $EnterPressed = $True
                Return $Selection
                Clear-Host
                break
            }

            38{
                If ($Selection -eq 0){
                    $Selection = $MaxValue
                } Else {
                    $Selection -= 1
                }
                Clear-Host
                break
            }

            40{
                If ($Selection -eq $MaxValue){
                    $Selection = 0
                } Else {
                    $Selection +=1
                }
                Clear-Host
                break
            }
            Default{
                Clear-Host
            }
        }
    }
}

function MainMenu(){
    Param(
        [System.Management.Automation.PSCredential]$Credential,
        [Parameter(Mandatory=$False)]
        [String]$TenantEdition,
        [String]$O365ATP
    )



$MainMenu = CreateMenu -TenantEdition $TenantEdition -TenantDetail $true -O365ATP $O365ATP -MenuOptions @("Audit","Identity","Messaging","Application","Device","Quit")
    switch($MainMenu){
    0{
      AuditMenu -Credential $Credential
      }
    1{
      IdentityMenu -Credential $Credential
      }
    2{
      MessagingMenu -Credential $Credential
      }
    3{
      ApplicationMenu -Credential $Credential
      }
    4{
      DeviceMenu -Credential $Credential
      }
    5{
      Break
      }
    Default{
      MainMenu -Credential $Credential -TenantEdition $TenantEdition -TenantDetail $true -O365ATP $O365ATP
      }
    }
}

function AuditMenu(){
    Param(
        [System.Management.Automation.PSCredential]$Credential
    )

$AuditMenu = CreateMenu -MenuTitle "HARDEN 365 - AUDIT" -MenuOptions @("Audit Microsoft Defender for O365 with ORCA","Audit Administration Roles","Audit Users with licenses","Audit Autoforwarding","Audit Mailbox Permissions","Check DNS Records","<- Return")
    switch($AuditMenu){
    0{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-Host "Audit Messaging with ORCA"-ForegroundColor Red	
                mkdir -Force ".\Audit" | Out-Null
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
                try {Get-OrganizationConfig | Out-Null 
                } catch {Connect-ExchangeOnline  -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false}
                Invoke-ORCA -ExchangeEnvironmentName "O365Default" -Output HTML -OutputOptions @{HTML=@{OutputDirectory=".\Audit"}} -Connect $false
                Read-Host -Prompt "Press Enter to return_"
                AuditMenu -Credential $Credential
      }
    1{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("AUDIT ADMINISTRATION ROLES") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to Azure AD Powershell') -ForegroundColor Green
                try {
                Get-AzureADTenantDetail | Out-Null 
                } catch {Connect-AzureAD -Credential $Credential | Out-Null} 
                Connect-MsolService -Credential $Credential | Out-Null

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Get-AADRolesAudit'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                AuditMenu -Credential $Credential
      }
    2{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("AUDIT USERS WITH LICENCES") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to  MSOL Service') -ForegroundColor Green
                try { Get-AzureADTenantDetail | Out-Null 
                } catch {Connect-AzureAD -Credential $Credential | Out-Null} 
                Connect-MsolService -Credential $Credential | Out-Null

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Get-MSOAuditUsers'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                AuditMenu -Credential $Credential
      }
    3{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("AUDIT AUTOFORWARDING") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to  ExchangeOnline Powershell') -ForegroundColor Green
                try {Get-OrganizationConfig | Out-Null 
                } catch {Connect-ExchangeOnline  -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false}

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.Name -match 'Start-EOPCheckAutoForward'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                AuditMenu -Credential $Credential
      }
     4{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("AUDIT MAILBOX PERMISSIONS") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to  ExchangeOnline Powershell') -ForegroundColor Green
                try {Get-OrganizationConfig | Out-Null 
                } catch {Connect-ExchangeOnline  -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false}

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.Name -match 'Start-EOPCheckPermissionsMailbox'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                AuditMenu -Credential $Credential
      }
     5{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("CHECK DNS RECORDS (SPF/DKIM/DMARC)") -ForegroundColor Red
             Connect-ExchangeOnline  -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.name -match 'Start-AuditSPFDKIMDMARC' })
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.DKIM module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             AuditMenu -Credential $Credential
      }
     6{
       MainMenu -Credential $Credential -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    Default{
      AuditMenu -Credential $Credential
      }
    }
}

function IdentityMenu(){
    Param(
        [System.Management.Automation.PSCredential]$Credential
    )
$IdentityMenu = CreateMenu -MenuTitle "HARDEN 365 - IDENTITY" -MenuOptions @("Emergency Account","MFA per User","Conditionnal Access Models AAD","Export user configuration MFA","Import user configuration MFA","<- Return")
        switch($IdentityMenu){
    0{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING TIER MODEL") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to Azure AD Powershell') -ForegroundColor Green
                try {
                Get-AzureADTenantDetail | Out-Null 
                } catch {Connect-AzureAD -Credential $Credential | Out-Null} 
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to  MSOL Service') -ForegroundColor Green
                Connect-MsolService  -Credential $Credential | Out-Null
                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.TierModel'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                } Catch {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host(" --> Harden365.TierModel module not working") -ForegroundColor Red}
                }
                Read-Host -Prompt "Press Enter to return_"
                IdentityMenu -Credential $Credential
                }
    1{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING ENABLE MFA PER USER") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to  MSOL Service') -ForegroundColor Green
                Connect-MsolService  -Credential $Credential | Out-Null
               $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.MFAperUser'})
               $scriptFunctions | ForEach-Object {
               Try { 
               & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
               } Catch {
               write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host(" --> Harden365.MFAperUser module not working") -ForegroundColor Red}
               }
               Read-Host -Prompt "Press Enter to return_"
               IdentityMenu -Credential $Credential
      }
    2{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING CONDITIONNAL ACCESS FOR AAD") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to  AzureAD') -ForegroundColor Green
                try {
                Get-AzureADTenantDetail | Out-Null 
                } catch {Connect-AzureAD  -Credential $Credential | Out-Null} 
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to  MSOL Service') -ForegroundColor Green
                Connect-MsolService  -Credential $Credential | Out-Null
                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.CA'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
                } Catch {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host(" --> Harden365.CA module not working") -ForegroundColor Red}
                }
                Read-Host -Prompt "Press Enter to return_"
                IdentityMenu -Credential $Credential
      }
    3{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING EXPORT CONFIG MFA") -ForegroundColor Red
                Connect-MsolService  -Credential $Credential | Out-Null
                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ExportForCA'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                IdentityMenu -Credential $Credential
      }
    4{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING IMPORT CONFIG MFA") -ForegroundColor Red
                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ImportPhoneNumbers'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                IdentityMenu -Credential $Credential
      }
    5{
      MainMenu -Credential $Credential -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    Default{
      IdentityMenu -Credential $Credential
      }
    }
}

function MessagingMenu(){
    Param(
        [System.Management.Automation.PSCredential]$Credential
    )
$MessagingMenu = CreateMenu -MenuTitle "HARDEN 365 - MESSAGING" -MenuOptions @("Exchange Online Protection","Defender for Office365","Check Autoforward","Check DNS Records","DKIM Configuration","<- Return")
        switch($MessagingMenu){
    0{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host(" HARDENING EXCHANGE ONLINE PROTECTION") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
             try {Get-OrganizationConfig | Out-Null 
             } catch {Connect-ExchangeOnline  -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false}
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ExchangeOnline' }) 
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.ExchangeOnline module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             MessagingMenu -Credential $Credential
                }
    1{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING DEFENDER FOR OFFICE365") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
             try {Get-OrganizationConfig | Out-Null 
             } catch {Connect-ExchangeOnline  -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false}
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ExchangeOnline' }) 
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.ExchangeOnline module not working") -ForegroundColor Red}
             }
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.DefenderForO365'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.DefenderForO365 module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             MessagingMenu -Credential $Credential
      }
    2{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host(" CHECK AUTOFORWARDING") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
             try {Get-OrganizationConfig | Out-Null 
             } catch {Connect-ExchangeOnline  -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false}
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.Name -match 'Start-EOPCheckAutoForward' })
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.ExchangeOnline module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             MessagingMenu -Credential $Credential
      }
    3{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("CHECK DNS RECORDS (SPF/DKIM/DMARC)") -ForegroundColor Red
             Connect-ExchangeOnline  -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.Name -match 'Start-AuditSPFDKIMDMARC' })
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.DKIM module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             MessagingMenu -Credential $Credential
      }
    4{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("DKIM CONFIGURATION)") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
             Connect-ExchangeOnline  -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
             $scriptFunctions=(Get-ChildItem function: | Where-Object { ($_.source -match 'Harden365.DKIM') -and ($_.Name -notmatch 'Start-AuditSPFDKIMDMARC')})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.DKIM module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             MessagingMenu -Credential $Credential
      }
    5{
      MainMenu -Credential $Credential -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    Default{
      MessagingMenu -Credential $Credential
      }
    }
}

function ApplicationMenu(){
    Param(
        [System.Management.Automation.PSCredential]$Credential
    )
$ApplicationMenu = CreateMenu -MenuTitle "HARDEN 365 - APPLICATIONS" -MenuOptions @("Audit Applications","Hardening Outlook","Hardening MS Teams","Hardening Sharepoint","Hardening PowerPlatform","<- Return")
        switch($ApplicationMenu){
    0{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("AUDIT APPLICATIONS") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to MSOlService Powershell') -ForegroundColor Green
             Connect-MSOlService -Credential $Credential -WarningAction:SilentlyContinue
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
             Connect-ExchangeOnline  -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to MSTeams Powershell') -ForegroundColor Green
             Connect-MicrosoftTeams -Credential $credential
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to MSPowerApps Powershell') -ForegroundColor Green
             $scriptFunctions=(Get-ChildItem function: | Where-Object { ($_.source -match 'Harden365.AuditApplications') -and ($_.Name -notmatch 'Start-OUTCheckAddIns')})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -credential $credential -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.AuditApplications module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             ApplicationMenu -Credential $Credential
      }
    1{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING OUTLOOK") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
             Connect-ExchangeOnline  -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.Outlook'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.Teams module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             ApplicationMenu -Credential $Credential
      }
    2{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING MICROSOFT TEAMS") -ForegroundColor Red
             Connect-MicrosoftTeams -Credential $credential
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to MSTeams Powershell') -ForegroundColor Green
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.Teams'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.Teams module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             ApplicationMenu -Credential $Credential
      }
     3{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING SHAREPOINT") -ForegroundColor Red
             Connect-ExchangeOnline  -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to SPO Powershell') -ForegroundColor Green
             $URLSPO = (Get-OrganizationConfig).SharePointUrl -split '.sharepoint.com/'
             $AdminSPO= $URLSPO -join'-admin.sharepoint.com'
             Connect-SPOService -Url $AdminSPO -Credential $Credential -WarningAction:SilentlyContinue
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.Sharepoint'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name -credential $credential -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.Sharepoint module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             ApplicationMenu -Credential $Credential
      }
    4{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING POWERPLATFORM") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to MSOlService Powershell') -ForegroundColor Green
             Connect-MSOlService -Credential $Credential -WarningAction:SilentlyContinue
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.PowerPlatform'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name -credential $credential -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.PowerPlatform module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             ApplicationMenu -Credential $Credential
      }

      5{
      MainMenu -Credential $Credential -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    Default{
      ApplicationMenu -Credential $Credential
      }
    }
}

function DeviceMenu(){
    Param(
        [System.Management.Automation.PSCredential]$Credential
    )
$DeviceMenu = CreateMenu -MenuTitle "HARDEN 365 - DEVICE" -MenuOptions @("N/A","N/A","N/A","N/A","<- Return")
        switch($DeviceMenu){
    0{
      DeviceMenu -Credential $Credential
      }
    1{
      DeviceMenu -Credential $Credential
      }
    2{
      DeviceMenu -Credential $Credential
      }
    3{
      DeviceMenu -Credential $Credential
      }
    4{
      MainMenu -Credential $Credential -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    Default{
      DeviceMenu -Credential $Credential
      }
    }
}