$FrontStyle = '
            _________________________________________________________________________________________
            
            '
Function CreateMenu () {
    
  Param(
    [Parameter(Mandatory = $False)]
    [String]$MenuTitle,
    [String]$TenantEdition,
    [String]$TenantName,
    [String]$O365ATP,
    [Boolean]$TenantDetail = $false,
    [Parameter(Mandatory = $True)][array]$MenuOptions
  )

  $MaxValue = $MenuOptions.count - 1
  $Selection = 0
  $EnterPressed = $False

  $FrontStyle = '    _________________________________________________________________________________________            
            '
    
  Clear-Host

  While ($EnterPressed -eq $False) {
    $LogoData = Get-Content ('.\Config\Harden365.logo')
    foreach ($line in $LogoData) {
      Write-Host $line
    }
 
    Write-Host "    $MenuTitle" -ForegroundColor Red
    Write-Host $FrontStyle -ForegroundColor Red

    if ($TenantDetail -eq $True) {
      Write-Host '    Tenant               = ' -NoNewline -ForegroundColor Red
      Write-Host "$TenantName" -ForegroundColor Yellow
      Write-Host '    AzureAD Edition      = ' -NoNewline -ForegroundColor Red
      Write-Host "$TenantEdition"
      Write-Host '    DefenderO365 Edition = ' -NoNewline -ForegroundColor Red
      Write-Host "$O365ATP"
      Write-Host $FrontStyle -ForegroundColor Red
    }
    For ($i = 0; $i -le $MaxValue; $i++) {
            
      If ($i -eq $Selection) {
        Write-Host -NoNewline '    '
        Write-Host -BackgroundColor yellow -ForegroundColor Black "[ $($MenuOptions[$i]) ]"
      }
      Else {
        Write-Host "      $($MenuOptions[$i])  "
      }

    }

    $KeyInput = $host.ui.rawui.readkey('NoEcho,IncludeKeyDown').virtualkeycode

    Switch ($KeyInput) {
      13 {
        $EnterPressed = $True
        Return $Selection
        Clear-Host
        break
      }

      38 {
        If ($Selection -eq 0) {
          $Selection = $MaxValue
        }
        Else {
          $Selection -= 1
        }
        Clear-Host
        break
      }

      40 {
        If ($Selection -eq $MaxValue) {
          $Selection = 0
        }
        Else {
          $Selection += 1
        }
        Clear-Host
        break
      }
      Default {
        Clear-Host
      }
    }
  }
}

function MainMenu() {
  Param(
    [System.Management.Automation.PSCredential]$Credential,
    [Parameter(Mandatory = $False)]
    [String]$TenantName,
    [String]$TenantEdition,
    [String]$O365ATP
  )



  $MainMenu = CreateMenu -TenantName $TenantName -TenantEdition $TenantEdition -TenantDetail $true -O365ATP $O365ATP -MenuOptions @('Audit', 'Identity', 'Messaging', 'Application', 'Device', 'Quit')
  switch ($MainMenu) {
    0 {
      AuditMenu -Credential $Credential
    }
    1 {
      IdentityMenu -Credential $Credential
    }
    2 {
      MessagingMenu -Credential $Credential
    }
    3 {
      ApplicationMenu -Credential $Credential
    }
    4 {
      DeviceMenu -Credential $Credential
    }
    5 {
      Break
    }
    Default {
      MainMenu -Credential $Credential -TenantName $TenantName -TenantEdition $TenantEdition -TenantDetail $true -O365ATP $O365ATP
    }
  }
}

function AuditMenu() {
  Param(
    [System.Management.Automation.PSCredential]$Credential
  )

  $AuditMenu = CreateMenu -MenuTitle 'HARDEN 365 - AUDIT' -MenuOptions @('Audit Microsoft Defender for O365 with ORCA', 'Audit Administration Roles', 'Audit Users with licenses', 'Audit Autoforwarding', 'Audit Mailbox Permissions', 'Check DNS Records', '<- Return')
  switch ($AuditMenu) {
    0 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host 'Audit Messaging with ORCA'-ForegroundColor Red	
      mkdir -Force '.\Audit' | Out-Null
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
      try {
        Get-OrganizationConfig | Out-Null 
      }
      catch {
        Connect-ExchangeOnline -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
      }
      Invoke-ORCA -ExchangeEnvironmentName 'O365Default' -Output HTML -OutputOptions @{HTML = @{OutputDirectory = '.\Audit' } } -Connect $false
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Audit ORCA exported in folder .\Audit') -ForegroundColor Green
      Read-Host -Prompt 'Press Enter to return_'
      AuditMenu -Credential $Credential
    }
    1 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('AUDIT ADMINISTRATION ROLES') -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to Azure AD Powershell') -ForegroundColor Green
      try {
        Get-AzureADTenantDetail | Out-Null 
      }
      catch {
        Connect-AzureAD -Credential $Credential | Out-Null
      } 
      Connect-MsolService -Credential $Credential | Out-Null

      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Get-AADRolesAudit' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -ErrorAction:SilentlyContinue | Out-Null 
        }
        Catch {
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      AuditMenu -Credential $Credential
    }
    2 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('AUDIT USERS WITH LICENCES') -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to  MSOL Service') -ForegroundColor Green
      try {
        Get-AzureADTenantDetail | Out-Null 
      }
      catch {
        Connect-AzureAD -Credential $Credential | Out-Null
      } 
      Connect-MsolService -Credential $Credential | Out-Null

      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Get-MSOAuditUsers' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      AuditMenu -Credential $Credential
    }
    3 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('AUDIT AUTOFORWARDING') -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to  ExchangeOnline Powershell') -ForegroundColor Green
      try {
        Get-OrganizationConfig | Out-Null 
      }
      catch {
        Connect-ExchangeOnline -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
      }

      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.Name -match 'Start-EOPCheckAutoForward' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      AuditMenu -Credential $Credential
    }
    4 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('AUDIT MAILBOX PERMISSIONS') -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to  ExchangeOnline Powershell') -ForegroundColor Green
      try {
        Get-OrganizationConfig | Out-Null 
      }
      catch {
        Connect-ExchangeOnline -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
      }

      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.Name -match 'Start-EOPCheckPermissionsMailbox' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      AuditMenu -Credential $Credential
    }
    5 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('CHECK DNS RECORDS (SPF/DKIM/DMARC)') -ForegroundColor Red
      Connect-ExchangeOnline -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.name -match 'Start-AuditSPFDKIMDMARC' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
          Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('ERROR --> Harden365.DKIM module not working') -ForegroundColor Red
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      AuditMenu -Credential $Credential
    }
    6 {
      MainMenu -Credential $Credential -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
    }
    Default {
      AuditMenu -Credential $Credential
    }
  }
}

function IdentityMenu() {
  Param(
    [System.Management.Automation.PSCredential]$Credential
  )
  $IdentityMenu = CreateMenu -MenuTitle 'HARDEN 365 - IDENTITY' -MenuOptions @('Emergency Accounts', 'MFA per User', 'Conditionnal Access Models AAD', 'Export user configuration MFA', 'Import user configuration MFA', '<- Return')
  switch ($IdentityMenu) {
    0 {
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('Do you want to create Emergency Accounts (Y/N) : ') -NoNewline -ForegroundColor Yellow ; $QID0 = Read-Host
      if ($QID0 -eq 'Y') {             
        Write-Host $FrontStyle -ForegroundColor Red
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('HARDENING TIER MODEL') -ForegroundColor Red
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to Azure AD Powershell') -ForegroundColor Green
        try {
          Get-AzureADTenantDetail | Out-Null 
        }
        catch {
          Connect-AzureAD -Credential $Credential | Out-Null
        } 
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to  MSOL Service') -ForegroundColor Green
        Connect-MsolService -Credential $Credential | Out-Null
        $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.TierModel' })
        $scriptFunctions | ForEach-Object {
          Try { 
            & $_.Name -ErrorAction:SilentlyContinue | Out-Null
          }
          Catch {
            Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host(' --> Harden365.TierModel module not working') -ForegroundColor Red
          }
        }
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Emergency Accounts credentials are saved in .\Keepass file') -ForegroundColor Green
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Password Keepass is : ') -ForegroundColor Green -NoNewline ; Write-Host ('Harden365') -ForegroundColor Red
        Read-Host -Prompt 'Press Enter to return_'
        IdentityMenu -Credential $Credential
      }
      else {
        IdentityMenu -Credential $Credential
      }
    }
    1 {
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('Do you want to configure Legacy MFA (Y/N) : ') -NoNewline -ForegroundColor Yellow ; $QID1 = Read-Host
      if ($QID1 -eq 'Y') {   
        Write-Host $FrontStyle -ForegroundColor Red
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('HARDENING ENABLE MFA PER USER') -ForegroundColor Red
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to  MSOL Service') -ForegroundColor Green
        Connect-MsolService -Credential $Credential | Out-Null
        $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.MFAperUser' })
        $scriptFunctions | ForEach-Object {
          Try { 
            & $_.Name -ErrorAction:SilentlyContinue | Out-Null
          }
          Catch {
            Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host(' --> Harden365.MFAperUser module not working') -ForegroundColor Red
          }
        }
        Read-Host -Prompt 'Press Enter to return_'
        IdentityMenu -Credential $Credential
      }
      else {
        IdentityMenu -Credential $Credential
      }
    }
    2 {
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('Do you want to create Conditionnal Access Templates (Y/N) : ') -NoNewline -ForegroundColor Yellow ; $QID2 = Read-Host
      if ($QID2 -eq 'Y') {
        Write-Host $FrontStyle -ForegroundColor Red
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('HARDENING CONDITIONNAL ACCESS FOR AAD') -ForegroundColor Red
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to  AzureAD') -ForegroundColor Green
        try {
          Get-AzureADTenantDetail | Out-Null 
        }
        catch {
          Connect-AzureAD -Credential $Credential | Out-Null
        } 
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to  MSOL Service') -ForegroundColor Green
        Connect-MsolService -Credential $Credential | Out-Null
        $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.CA' })
        $scriptFunctions | ForEach-Object {
          Try { 
            & $_.Name -ErrorAction:SilentlyContinue | Out-Null
          }
          Catch {
            Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host(' --> Harden365.CA module not working') -ForegroundColor Red
          }
        }
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('All CA Template created is disable by default') -ForegroundColor Green
        Read-Host -Prompt 'Press Enter to return_'
        IdentityMenu -Credential $Credential
      }
      else {
        IdentityMenu -Credential $Credential
      }
    }
    3 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('HARDENING EXPORT CONFIG MFA') -ForegroundColor Red
      Connect-MsolService -Credential $Credential | Out-Null
      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ExportForCA' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      IdentityMenu -Credential $Credential
    }
    4 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('HARDENING IMPORT CONFIG MFA') -ForegroundColor Red
      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ImportPhoneNumbers' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      IdentityMenu -Credential $Credential
    }
    5 {
      MainMenu -Credential $Credential -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
    }
    Default {
      IdentityMenu -Credential $Credential
    }
  }
}

function MessagingMenu() {
  Param(
    [System.Management.Automation.PSCredential]$Credential
  )
  $MessagingMenu = CreateMenu -MenuTitle 'HARDEN 365 - MESSAGING' -MenuOptions @('Exchange Online Protection', 'Defender for Office365', 'Check Autoforward', 'Check DNS Records', 'DKIM Configuration', '<- Return')
  switch ($MessagingMenu) {
    0 {
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('Do you want to secure Exchange Online Protection (Y/N) : ') -NoNewline -ForegroundColor Yellow ; $QMS0 = Read-Host
      if ($QMS0 -eq 'Y') { 
        Write-Host $FrontStyle -ForegroundColor Red
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host(' HARDENING EXCHANGE ONLINE PROTECTION') -ForegroundColor Red
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
        try {
          Get-OrganizationConfig | Out-Null 
        }
        catch {
          Connect-ExchangeOnline -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
        }
        $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ExchangeOnline' }) 
        $scriptFunctions | ForEach-Object {
          Try { 
            & $_.Name -ErrorAction:SilentlyContinue | Out-Null
          }
          Catch {
            Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('ERROR --> Harden365.ExchangeOnline module not working') -ForegroundColor Red
          }
        }
        Read-Host -Prompt 'Press Enter to return_'
        MessagingMenu -Credential $Credential
      }
      else {
        MessagingMenu -Credential $Credential
      }
    }
    1 {
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('Do you want to secure Defender for Office365 (Y/N) : ') -NoNewline -ForegroundColor Yellow ; $QMS1 = Read-Host
      if ($QMS1 -eq 'Y') { 
        Write-Host $FrontStyle -ForegroundColor Red
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('HARDENING DEFENDER FOR OFFICE365') -ForegroundColor Red
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
        try {
          Get-OrganizationConfig | Out-Null 
        }
        catch {
          Connect-ExchangeOnline -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
        }
        $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ExchangeOnline' }) 
        $scriptFunctions | ForEach-Object {
          Try { 
            & $_.Name -ErrorAction:SilentlyContinue | Out-Null
          }
          Catch {
            Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('ERROR --> Harden365.ExchangeOnline module not working') -ForegroundColor Red
          }
        }
        $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.DefenderForO365' })
        $scriptFunctions | ForEach-Object {
          Try { 
            & $_.Name -ErrorAction:SilentlyContinue | Out-Null
          }
          Catch {
            Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('ERROR --> Harden365.DefenderForO365 module not working') -ForegroundColor Red
          }
        }
        Read-Host -Prompt 'Press Enter to return_'
        MessagingMenu -Credential $Credential
      }
      else {
        MessagingMenu -Credential $Credential
      }
    }
    2 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host(' CHECK AUTOFORWARDING') -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
      try {
        Get-OrganizationConfig | Out-Null 
      }
      catch {
        Connect-ExchangeOnline -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
      }
      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.Name -match 'Start-EOPCheckAutoForward' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
          Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('ERROR --> Harden365.ExchangeOnline module not working') -ForegroundColor Red
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      MessagingMenu -Credential $Credential
    }
    3 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('CHECK DNS RECORDS (SPF/DKIM/DMARC)') -ForegroundColor Red
      Connect-ExchangeOnline -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.Name -match 'Start-AuditSPFDKIMDMARC' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
          Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('ERROR --> Harden365.DKIM module not working') -ForegroundColor Red
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      MessagingMenu -Credential $Credential
    }
    4 {
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('Do you want to configure DKIM (Y/N) : ') -NoNewline -ForegroundColor Yellow ; $QMS4 = Read-Host
      if ($QMS4 -eq 'Y') { 
        Write-Host $FrontStyle -ForegroundColor Red
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('DKIM CONFIGURATION)') -ForegroundColor Red
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
        Connect-ExchangeOnline -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
        $scriptFunctions = (Get-ChildItem function: | Where-Object { ($_.source -match 'Harden365.DKIM') -and ($_.Name -notmatch 'Start-AuditSPFDKIMDMARC') })
        $scriptFunctions | ForEach-Object {
          Try { 
            & $_.Name -ErrorAction:SilentlyContinue | Out-Null
          }
          Catch {
            Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('ERROR --> Harden365.DKIM module not working') -ForegroundColor Red
          }
        }
        Read-Host -Prompt 'Press Enter to return_'
        MessagingMenu -Credential $Credential
      }
      else {
        MessagingMenu -Credential $Credential
      }
    }
    5 {
      MainMenu -Credential $Credential -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
    }
    Default {
      MessagingMenu -Credential $Credential
    }
  }
}

function ApplicationMenu() {
  Param(
    [System.Management.Automation.PSCredential]$Credential
  )
  $ApplicationMenu = CreateMenu -MenuTitle 'HARDEN 365 - APPLICATIONS' -MenuOptions @('Audit Applications', 'Hardening Outlook', 'Hardening MS Teams', 'Hardening Sharepoint', 'Hardening PowerPlatform', '<- Return')
  switch ($ApplicationMenu) {
    0 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('AUDIT APPLICATIONS') -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to MSOlService Powershell') -ForegroundColor Green
      Connect-MSOlService -Credential $Credential -WarningAction:SilentlyContinue
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
      Connect-ExchangeOnline -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to MSTeams Powershell') -ForegroundColor Green
      Connect-MicrosoftTeams -Credential $credential
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to MSPowerApps Powershell') -ForegroundColor Green
      $scriptFunctions = (Get-ChildItem function: | Where-Object { ($_.source -match 'Harden365.AuditApplications') -and ($_.Name -notmatch 'Start-OUTCheckAddIns') })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -credential $credential -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
          Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('ERROR --> Harden365.AuditApplications module not working') -ForegroundColor Red
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      ApplicationMenu -Credential $Credential
    }
    1 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('HARDENING OUTLOOK') -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
      Connect-ExchangeOnline -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.Outlook' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
          Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('ERROR --> Harden365.Teams module not working') -ForegroundColor Red
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      ApplicationMenu -Credential $Credential
    }
    2 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('HARDENING MICROSOFT TEAMS') -ForegroundColor Red
      Connect-MicrosoftTeams -Credential $credential
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to MSTeams Powershell') -ForegroundColor Green
      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.Teams' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
          Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('ERROR --> Harden365.Teams module not working') -ForegroundColor Red
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      ApplicationMenu -Credential $Credential
    }
    3 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('HARDENING SHAREPOINT') -ForegroundColor Red
      Connect-ExchangeOnline -Credential $Credential -WarningAction:SilentlyContinue -ShowBanner:$false
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to SPO Powershell') -ForegroundColor Green
      $URLSPO = (Get-OrganizationConfig).SharePointUrl -split '.sharepoint.com/'
      $AdminSPO = $URLSPO -join '-admin.sharepoint.com'
      Connect-SPOService -Url $AdminSPO -Credential $Credential -WarningAction:SilentlyContinue
      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.Sharepoint' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -credential $credential -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
          Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('ERROR --> Harden365.Sharepoint module not working') -ForegroundColor Red
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      ApplicationMenu -Credential $Credential
    }
    4 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('HARDENING POWERPLATFORM') -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to MSOlService Powershell') -ForegroundColor Green
      Connect-MSOlService -Credential $Credential -WarningAction:SilentlyContinue
      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.PowerPlatform' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -credential $credential -ErrorAction:SilentlyContinue | Out-Null
        }
        Catch {
          Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('ERROR --> Harden365.PowerPlatform module not working') -ForegroundColor Red
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      ApplicationMenu -Credential $Credential
    }

    5 {
      MainMenu -Credential $Credential -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
    }
    Default {
      ApplicationMenu -Credential $Credential
    }
  }
}

function DeviceMenu() {
  Param(
    [System.Management.Automation.PSCredential]$Credential,
    [String]$AccessSecret
  )
  $DeviceMenu = CreateMenu -MenuTitle 'HARDEN 365 - DEVICE' -MenuOptions @('Install Harden365 App', 'Hardening Intune', '<- Return')
  switch ($DeviceMenu) {
    0 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('INSTALL HARDEN365 APP') -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to Azure AD Powershell') -ForegroundColor Green
      try {
        Get-AzureADTenantDetail | Out-Null 
      }
      catch {
        Connect-AzureAD -Credential $Credential | Out-Null
      } 
                
      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.Name -match 'Start-Harden365App' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -ErrorAction:SilentlyContinue | Out-Null 
        }
        Catch {
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      DeviceMenu -Credential $Credential -AccessSecret $AccessSecret
    }
    1 {
      Write-Host $FrontStyle -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('HARDENING INTUNE') -ForegroundColor Red
      Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host ('Connecting to Azure AD Powershell') -ForegroundColor Green
      try {
        Get-AzureADTenantDetail | Out-Null 
      }
      catch {
        Connect-AzureAD -Credential $Credential | Out-Null
      } 
      Connect-MsolService -Credential $Credential | Out-Null
      if (!$AccessSecret) {
        Write-Host $(Get-Date -UFormat '%m-%d-%Y %T ') -NoNewline ; Write-Host('Please insert Secret of Harden365App :') -NoNewline -ForegroundColor Yellow ; $AccessSecret = Read-Host
      }

      $scriptFunctions = (Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.Device' })
      $scriptFunctions | ForEach-Object {
        Try { 
          & $_.Name -Accesssecret $AccessSecret -ErrorAction:SilentlyContinue | Out-Null 
        }
        Catch {
        }
      }
      Read-Host -Prompt 'Press Enter to return_'
      DeviceMenu -Credential $Credential -AccessSecret $AccessSecret
    }
    2 {
      MainMenu -Credential $Credential -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
    }
    Default {
      DeviceMenu -Credential $Credential -AccessSecret $AccessSecret
    }
  }
}