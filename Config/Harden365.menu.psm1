$FrontStyle = "
            _________________________________________________________________________________________
            
            "
Function CreateMenu (){
    
    Param(
        [Parameter(Mandatory=$False)]
        [String]$MenuTitle,
        [String]$TenantEdition,
        [String]$TenantName,
        [String]$O365ATP,
        [Boolean]$TenantDetail = $false,
        [Parameter(Mandatory=$True)][array]$MenuOptions
    )

    $MaxValue = $MenuOptions.count-1
    $Selection = 0
    $EnterPressed = $False

#TENANT NAME
$TenantName = (Get-MgDomain | Where-Object { $_.IsDefault -eq $true }).Id
#AZUREADEDITION
if (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "AAD_PREMIUM_P2")
{ $TenantEdition = "Entra ID P2"} 
elseif (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "AAD_PREMIUM")
{ $TenantEdition = "Entra ID P1"} 
elseif (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "AAD_BASIC")
{ $TenantEdition = "Entra ID  Basic"} 
else
{ $TenantEdition = "Entra ID  Free" }
#OFFICE365ATP
if (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "THREAT_INTELLIGENCE")
    { $O365ATP = "Defender for Office365 P2" }   
elseif (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "ATP_ENTERPRISE")
    { $O365ATP = "Defender for Office365 P1" }  
elseif (((Get-MgSubscribedSku | Where-Object { $_.CapabilityStatus -eq "Enabled" }).ServicePlans).ServicePlanName -match "EOP_ENTERPRISE")
    { $O365ATP = "Exchange Online Protection" }  
else
{ $O365ATP = "No protection" }

$FrontStyle = "    _________________________________________________________________________________________            
            "
    
    Clear-Host

    While($EnterPressed -eq $False){
    $LogoData = Get-Content (".\Config\Harden365s.logo")
        foreach ($line in $LogoData){Write-Host $line}
 
        Write-Host "    $MenuTitle" -ForegroundColor Red
        Write-Host $FrontStyle -ForegroundColor Red

    if ($TenantDetail -eq $True) {
        write-Host "    Tenant               = " -NoNewline -ForegroundColor Red
        write-Host "$TenantName" -ForegroundColor Yellow
        write-Host "    Entra Edition        = " -NoNewline -ForegroundColor Red
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
        [Parameter(Mandatory=$False)]
        [String]$TenantName,
        [String]$TenantEdition,
        [String]$O365ATP
    )



$MainMenu = CreateMenu -TenantName $TenantName -TenantEdition $TenantEdition -TenantDetail $true -O365ATP $O365ATP -MenuOptions @("Audit","Identity","Messaging","Application","Device","Quit")
    switch($MainMenu){
    0{
      AuditMenu -TenantEdition $TenantEdition -TenantName $TenantName -O365ATP $O365ATP
      }
    1{
      IdentityMenu -TenantEdition $TenantEdition -TenantName $TenantName -O365ATP $O365ATP
      }
    2{
      MessagingMenu  -TenantEdition $TenantEdition -TenantName $TenantName -O365ATP $O365ATP
      }
    3{
      ApplicationMenu
      }
    4{
      DeviceMenu
      }
    5{
      Break
      }
    Default{
      MainMenu -TenantName $TenantName -TenantEdition $TenantEdition -TenantDetail $true -O365ATP $O365ATP
      }
    }
}

function AuditMenu(){
    Param(
        [String]$TenantName,
        [String]$TenantEdition,
        [String]$O365ATP

    )

$AuditMenu = CreateMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP -MenuTitle "HARDEN 365 - AUDIT" -MenuOptions @("Audit Microsoft Defender for O365 with ORCA","Audit Administration Roles","Audit Identity Users","Audit Autoforwarding","Audit Mailbox Permissions","Check DNS Records","<- Return")
    switch($AuditMenu){
    0{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-Host "Audit Messaging with ORCA"-ForegroundColor Red	
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
                try {Get-OrganizationConfig | Out-Null 
                } catch {Connect-ExchangeOnline  -WarningAction:SilentlyContinue -ShowBanner:$false}
                Invoke-ORCA -ExchangeEnvironmentName "O365Default" -Output HTML -OutputOptions @{HTML=@{OutputDirectory="$TenantName"}} -Connect $false -ShowSurvey $false
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ("Audit ORCA exported in folder .\$TenantName") -ForegroundColor Green
                Read-Host -Prompt "Press Enter to return_"
                AuditMenu  -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    1{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("AUDIT ADMINISTRATION ROLES") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connected to Graph') -ForegroundColor Green
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ("EntraID Edition : $TenantEdition") -ForegroundColor Green
                if ( $TenantEdition -eq "Entra ID P2"){
                    $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.Name -match 'Get-AADRolesAuditP2'})
                    }
                else {
                    $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.Name -match 'Get-AADRolesAuditP1'})
                    }
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                Clear-Host
                AuditMenu  -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    2{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("AUDIT IDENTITY USERS") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connected to Graph') -ForegroundColor Green

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.Identity.Users'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                AuditMenu  -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    3{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("AUDIT AUTOFORWARDING") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to  ExchangeOnline Powershell') -ForegroundColor Green
                try {Get-OrganizationConfig | Out-Null 
                } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.Name -match 'Start-EOPCheckAutoForward'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                AuditMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    4{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("AUDIT MAILBOX PERMISSIONS") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to  ExchangeOnline Powershell') -ForegroundColor Green
                try {Get-OrganizationConfig | Out-Null 
                } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.Name -match 'Start-EOPCheckPermissionsMailbox'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                AuditMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    5{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("CHECK DNS RECORDS (SPF/DKIM/DMARC)") -ForegroundColor Red
                try {Get-OrganizationConfig | Out-Null 
                } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.name -match 'Start-AuditSPFDKIMDMARC' })
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.DKIM module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             AuditMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    6{
       MainMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    Default{
      AuditMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    }
}

function IdentityMenu(){
    Param(
        [System.Management.Automation.PSCredential]$Credential,
        [String]$TenantName,
        [String]$TenantEdition,
        [String]$O365ATP
    )
$IdentityMenu = CreateMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP -MenuTitle "HARDEN 365 - IDENTITY" -MenuOptions @("Emergency Accounts","MFA per User","Conditionnal Access Models AAD","Export user configuration MFA","Import user configuration MFA","<- Return")
        switch($IdentityMenu){
    0{
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("Do you want to create Emergency Accounts (Y/N) : ") -NoNewline -ForegroundColor Yellow ; $QID0 = Read-Host
                if ($QID0 -eq 'Y') {             
                    write-host $FrontStyle -ForegroundColor Red
                    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING TIER MODEL") -ForegroundColor Red
                    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to Graph') -ForegroundColor Green
                    $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.TierModel'})
                    $scriptFunctions | ForEach-Object {
                    Try { 
                    & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                    } Catch {
                    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host(" --> Harden365.TierModel module not working") -ForegroundColor Red}
                    }
                    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ("Emergency Account credentials are saved in .\$TenantName ->Keepass file") -ForegroundColor Green
                    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Password Keepass is : ') -ForegroundColor Green -NoNewline ; Write-host ('Harden365') -ForegroundColor Red
                    Read-Host -Prompt "Press Enter to return_"
                    IdentityMenu  -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
                }
                else { IdentityMenu  -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP}
                }
    1{
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("Do you want to configure Legacy MFA (Y/N) : ") -NoNewline -ForegroundColor Yellow ; $QID1 = Read-Host
                if ($QID1 -eq 'Y') {   
                    write-host $FrontStyle -ForegroundColor Red
                    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING ENABLE MFA PER USER") -ForegroundColor Red
                    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to MSOlService Powershell') -ForegroundColor Green
                    try { Get-MsolDomain -ErrorAction Stop > $null
                    } catch { Connect-MSOlService -WarningAction:SilentlyContinue}
                    $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.MFAperUser'})
                    $scriptFunctions | ForEach-Object {
                    Try { 
                    & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
                    } Catch {
                    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host(" --> Harden365.MFAperUser module not working") -ForegroundColor Red}
                    }
                    Read-Host -Prompt "Press Enter to return_"
                    IdentityMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
                }
                else {IdentityMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP}
                }
    2{
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("Do you want to create Conditionnal Access Templates (Y/N) : ") -NoNewline -ForegroundColor Yellow ; $QID2 = Read-Host
                if ($QID2 -eq 'Y') {
                    write-host $FrontStyle -ForegroundColor Red
                    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING CONDITIONNAL ACCESS FOR AAD") -ForegroundColor Red
                    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connected to Graph') -ForegroundColor Green
                    $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.CA'})
                    $scriptFunctions | ForEach-Object {
                    Try { 
                    & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
                    } Catch {
                    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host(" --> Harden365.CA module not working") -ForegroundColor Red}
                    }
                    write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('All CA Template created is disable by default') -ForegroundColor Green
                    Read-Host -Prompt "Press Enter to return_"
                    IdentityMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
                    }
                else {IdentityMenu -TenantName $TenantName -TenantEdition $TenantEdition  -O365ATP $O365ATP}
      }
    3{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING EXPORT CONFIG MFA") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to MSOlService Powershell') -ForegroundColor Green
                try { Get-MsolDomain -ErrorAction Stop > $null
                } catch { Connect-MSOlService -WarningAction:SilentlyContinue}
                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ExportForCA'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                IdentityMenu  -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    4{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING IMPORT CONFIG MFA") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connected to Graph') -ForegroundColor Green
                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ImportPhoneNumbers'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
                } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                IdentityMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    5{
      MainMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    Default{
      IdentityMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    }
}

function MessagingMenu(){
    Param(
        [String]$TenantName,
        [String]$TenantEdition,
        [String]$O365ATP
    )
$MessagingMenu = CreateMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP -MenuTitle "HARDEN 365 - MESSAGING" -MenuOptions @("Exchange Online Protection","Defender for Office365","Check Autoforward","Check DNS Records","DKIM Configuration","<- Return")
        switch($MessagingMenu){
    0{
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("Do you want to secure Exchange Online Protection (Y/N) : ") -NoNewline -ForegroundColor Yellow ; $QMS0 = Read-Host
             if ($QMS0 -eq 'Y') { 
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host(" HARDENING EXCHANGE ONLINE PROTECTION") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
                try {Get-OrganizationConfig | Out-Null 
                } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}
                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.ExchangeOnline' }) 
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
                } Catch {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.ExchangeOnline module not working") -ForegroundColor Red}
                }
                Read-Host -Prompt "Press Enter to return_"
                MessagingMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
                }
             else {MessagingMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP}
             }
    1{
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("Do you want to secure Defender for Office365 (Y/N) : ") -NoNewline -ForegroundColor Yellow ; $QMS1 = Read-Host
             if ($QMS1 -eq 'Y') { 
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING DEFENDER FOR OFFICE365") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
                try {Get-OrganizationConfig | Out-Null 
                } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}
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
                MessagingMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
                }
             else {MessagingMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP}
             }
    2{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host(" CHECK AUTOFORWARDING") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
             try {Get-OrganizationConfig | Out-Null 
             } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.Name -match 'Start-EOPCheckAutoForward' })
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.ExchangeOnline module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             MessagingMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    3{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("CHECK DNS RECORDS (SPF/DKIM/DMARC)") -ForegroundColor Red
             try {Get-OrganizationConfig | Out-Null 
             } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.Name -match 'Start-AuditSPFDKIMDMARC' })
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.DKIM module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             MessagingMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    4{
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("Do you want to configure DKIM (Y/N) : ") -NoNewline -ForegroundColor Yellow ; $QMS4 = Read-Host
             if ($QMS4 -eq 'Y') { 
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("DKIM CONFIGURATION)") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
                try {Get-OrganizationConfig | Out-Null 
                } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}
                $scriptFunctions=(Get-ChildItem function: | Where-Object { ($_.source -match 'Harden365.DKIM') -and ($_.Name -notmatch 'Start-AuditSPFDKIMDMARC')})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
                } Catch {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.DKIM module not working") -ForegroundColor Red}
                }
                Read-Host -Prompt "Press Enter to return_"
                MessagingMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
                }
             else {MessagingMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP}
             }
    5{
      MainMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    Default{
      MessagingMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    }
}

function ApplicationMenu(){
    Param(
        [String]$TenantName,
        [String]$TenantEdition,
        [String]$O365ATP
    )
$ApplicationMenu = CreateMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP -MenuTitle "HARDEN 365 - APPLICATIONS" -MenuOptions @("Audit Applications","Hardening Outlook","Hardening MS Teams","Hardening Sharepoint","Hardening PowerPlatform","<- Return")
        switch($ApplicationMenu){
    0{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("AUDIT APPLICATIONS") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to MSOlService Powershell') -ForegroundColor Green
             try { Get-MsolDomain -ErrorAction Stop > $null
             } catch { Connect-MSOlService -WarningAction:SilentlyContinue}
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
             try {Get-OrganizationConfig | Out-Null 
             } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}
             try { Get-CsTenant -Erroraction Stop | Out-Null 
             } catch { 
                      try { 
                            write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("Connecting to MS Teams Powershell") -ForegroundColor green
                            Connect-MicrosoftTeams -ErrorAction Stop > $null
                           }
                      catch {
                              Connect-MicrosoftTeams | Out-Null
                            }
                      }
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to MSCommerce Powershell') -ForegroundColor Green
             $scriptFunctions=(Get-ChildItem function: | Where-Object { ($_.source -match 'Harden365.AuditApplications') -and ($_.Name -notmatch 'Start-OUTCheckAddIns')})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name  -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.AuditApplications module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             ApplicationMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    1{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING OUTLOOK") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to ExchangeOnline Powershell') -ForegroundColor Green
             try {Get-OrganizationConfig | Out-Null 
             } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.Outlook'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.Teams module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             ApplicationMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    2{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING MICROSOFT TEAMS") -ForegroundColor Red
             try {Get-CsTenant | Out-Null 
             } catch {Connect-MicrosoftTeams | Out-Null}
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to MSTeams Powershell') -ForegroundColor Green
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.Teams'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.Teams module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             ApplicationMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
     3{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING SHAREPOINT") -ForegroundColor Red
             try {Get-OrganizationConfig | Out-Null 
             } catch {Connect-ExchangeOnline -WarningAction:SilentlyContinue -ShowBanner:$false}
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to SPO Powershell') -ForegroundColor Green
             $URLSPO = (Get-OrganizationConfig).SharePointUrl -split '.sharepoint.com/'
             $AdminSPO= $URLSPO -join'-admin.sharepoint.com'
             Connect-SPOService -Url $AdminSPO -Credential $Credential -WarningAction:SilentlyContinue
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.Sharepoint'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.Sharepoint module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             ApplicationMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    4{
             write-host $FrontStyle -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING POWERPLATFORM") -ForegroundColor Red
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to MSOlService Powershell') -ForegroundColor Green
             try { Get-MsolDomain -ErrorAction Stop > $null
             } catch { Connect-MSOlService -WarningAction:SilentlyContinue}
             $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.PowerPlatform'})
             $scriptFunctions | ForEach-Object {
             Try { 
             & $_.Name -ErrorAction:SilentlyContinue | Out-Null
             } Catch {
             write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("ERROR --> Harden365.PowerPlatform module not working") -ForegroundColor Red}
             }
             Read-Host -Prompt "Press Enter to return_"
             ApplicationMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }

      5{
      MainMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    Default{
      ApplicationMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    }
}

function DeviceMenu(){
    Param(
      [String]$TenantName,
      [String]$TenantEdition,
      [String]$O365ATP,
      [String]$AccessSecret
    )
$DeviceMenu = CreateMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP -MenuTitle "HARDEN 365 - DEVICE" -MenuOptions @("Install Harden365 App","Hardening Intune","<- Return")
        switch($DeviceMenu){
    0{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("INSTALL HARDEN365 APP") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to Graph') -ForegroundColor Green
                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.Name -match 'Start-Harden365App'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -ErrorAction:SilentlyContinue | Out-Null } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                DeviceMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP -AccessSecret $AccessSecret
      }
    1{
                write-host $FrontStyle -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("HARDENING INTUNE") -ForegroundColor Red
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; Write-host ('Connecting to Graph') -ForegroundColor Green
                if (!$AccessSecret) {
                write-host $(Get-Date -UFormat "%m-%d-%Y %T ") -NoNewline ; write-host("Please insert Secret of Harden365App :") -NoNewline -ForegroundColor Yellow ; $AccessSecret = Read-Host}

                $scriptFunctions=(Get-ChildItem function: | Where-Object { $_.source -match 'Harden365.Device'})
                $scriptFunctions | ForEach-Object {
                Try { 
                & $_.Name -Accesssecret $AccessSecret -ErrorAction:SilentlyContinue | Out-Null } Catch {}
                }
                Read-Host -Prompt "Press Enter to return_"
                DeviceMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP -AccessSecret $AccessSecret
      }
    2{
      MainMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    Default{
      DeviceMenu -TenantName $TenantName -TenantEdition $TenantEdition -O365ATP $O365ATP
      }
    }
}

