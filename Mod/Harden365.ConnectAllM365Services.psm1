<#
.DESCRIPTION
    Connect ot Azure AD, Echange, Msol, SharePoint and Teams modules
.NOTES
    ===========================================================================
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 11/26/2021
        Version:      v0.5
    ===========================================================================
#>

function Connect-AllM365Services {
    param(
        [int]$OperationCount,
        [int]$OperationTotal
    )
    $numberOfServicesToConnect = 5
    $currentCountOfServicesToConnect = 0

    Update-ProgressionBarOuterLoop -Activity 'Connexion to M365 services' -Status 'In progress' -OperationCount $OperationCount -OperationTotal $OperationTotal

    Write-LogSection 'CONNEXION' -NoHostOutput
    $isConnectedAzureADBefore = $false
    Update-ProgressionBarInnerLoop -Activity 'Connexion to Azure AD' -Status 'In progress' -OperationCount $currentCountOfServicesToConnect -OperationTotal $numberOfServicesToConnect
    try {
        Get-AzureADSubscribedSku | Out-Null 
        Write-LogInfo 'Open Azure AD connexion found'
        $isConnectedBefore = $true
    }
    catch {
    } 
    if (-not $isConnectedAzureADBefore) {
        Write-LogInfo 'Connecting to Azure AD'
        Connect-AzureAD > $null
    }

    $currentCountOfServicesToConnect++
    Update-ProgressionBarInnerLoop -Activity 'Connexion to MSol' -Status 'In progress' -OperationCount $currentCountOfServicesToConnect -OperationTotal $numberOfServicesToConnect

    if (Get-MsolCompanyInformation -ErrorAction SilentlyContinue ) {
        Write-LogInfo 'Open Msol connexion detected'
    }
    else {
        Start-Sleep -Seconds 1
        Write-LogInfo 'Connecting Msol'
        Connect-MsolService
    }

    $currentCountOfServicesToConnect++
    Update-ProgressionBarInnerLoop -Activity 'Connexion to EXO' -Status 'In progress' -OperationCount $currentCountOfServicesToConnect -OperationTotal $numberOfServicesToConnect

    $isEXOConnectedBefore = $false
    try { 
        Get-EXOMailbox -Filter "UserPrincipalName  -eq '9'" -errorAction SilentlyContinue -Verbose:$false
        Write-LogInfo 'Open EXO connexion detected'
        $isEXOConnectedBefore = $true
    }
    catch {
    }
    if (-not $isEXOConnectedBefore) {    
        Start-Sleep -Seconds 1
        Write-LogInfo 'Connecting EXO'
        Connect-ExchangeOnline -ShowBanner:$false
    }

    #$currentCountOfServicesToConnect++
    #Update-ProgressionBarInnerLoop -Activity 'Connexion to EXOPS' -Status 'In progress'  -OperationCount $currentCountOfServicesToConnect -OperationTotal $numberOfServicesToConnect
    #
    #$isConnectedBefore = $false
    #try {
    #    Get-OrganizationConfig | Out-Null 
    #    Write-Verbose 'Open Exchange Online Admin connexion detected'
    #    $isConnectedBefore = $true
    #} catch {} 
    #if (-not $isConnectedBefore) {
    #    Write-Verbose 'Connecting to Exchange Online PS Admin center'
    #    Connect-EXOPSSession
    #}

    $currentCountOfServicesToConnect++
    Update-ProgressionBarInnerLoop -Activity 'Connexion to SPO' -Status 'In progress' -OperationCount $currentCountOfServicesToConnect -OperationTotal $numberOfServicesToConnect

    $isSPOConnectedBefore = $false
    try {
        Get-SPOTenant | Out-Null 
        Write-Verbose 'Open SPO Service connexion found'
        $isSPOConnectedBefore = $true
    }
    catch {
    } 
    if (-not $isSPOConnectedBefore) {
        $SPAdminURL = ((Get-OrganizationConfig).SharePointUrl.AbsoluteUri).replace('.sharepoint.com', '-admin.sharepoint.com')
        Write-Verbose "Connecting to SPO Service URL: $SPAdminURL" 
        Connect-SPOService -Url $SPAdminURL
    }

    $currentCountOfServicesToConnect++
    Update-ProgressionBarInnerLoop -Activity 'Connexion to Security and Compliance center' -Status 'In progress' -OperationCount $currentCountOfServicesToConnect -OperationTotal $numberOfServicesToConnect

    $isConnectedBefore = $false
    try {
        Get-Label | Out-Null 
        Write-Verbose 'Open compliance center connexion detected'
        $isConnectedBefore = $true
    }
    catch {
    } 
    if (-not $isConnectedBefore) {
        Write-Verbose 'Connecting to compliance center'
        Connect-IPPSSession
    }

    $currentCountOfServicesToConnect++
    Update-ProgressionBarInnerLoop -Activity 'Connexion to M365 services' -Status 'Completed' -OperationCount $currentCountOfServicesToConnect -OperationTotal $numberOfServicesToConnect

    Write-LogSection '' -NoHostOutput
}