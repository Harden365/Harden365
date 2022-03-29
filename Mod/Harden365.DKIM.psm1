<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.dkim.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 12/02/2021
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening Exchange Online Protection

    .DESCRIPTION
        Check DNS Record for SPF DMARC DKIM
        Check and extract DKIM configuration
        Enable and configure DKIM 
#>

Function Start-AuditSPFDKIMDMARC {
     <#
        .Synopsis
         Check DNS Record for SPF DMARC DKIM
        
        .Description
         This function check DNS Record for SPF DMARC DKIM

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
    [String]$Name = "Check SPF DMARC DKIM"

)

Write-LogSection 'SPF - DMARC - DKIM' -NoHostOutput

#SCRIPT

$Domains=(Get-AcceptedDomain | Where-Object { $_.DomainName -notmatch "onmicrosoft.com"}).Name

foreach ($Domain in $Domains) {
    $SPFResultes = Resolve-DnsName -Type TXT -Name $Domain -erroraction 'silentlycontinue'
        If ($SPFResultes -eq $Null){
            Write-LogWarning "No SPF Setting Found in $domain"
        } Else {
            $SPFResultesStrings =  ($SPFResultes   | Where-Object { $_.Strings -match "v=spf1"}).Strings
            Write-LogInfo "$Domain : Check SPF - $SPFResultesStrings"
        }
    $DKIMResultes = Resolve-DnsName -Type CNAME -Name selector1._domainkey.$Domain -erroraction 'silentlycontinue'
        If ($DKIMResultes -eq $Null){
            Write-LogWarning "No DKIM Setting Found in $Domain"
        } Else {
            $DKIMResultesString =  $DKIMResultes.NameHost
            Write-LogInfo "$Domain : Check DKIM - $DKIMResultesString"
        }
    $DMARCResultes = Resolve-DnsName -Type Txt -Name _dmarc.$Domain -erroraction 'silentlycontinue'
        If ($DMARCResultes -eq $Null){
            Write-LogWarning "No DMARC Setting Found in $Domain"
        } Else {
            $DMARCResultesStrings =  ($DMARCResultes   | Where-Object { $_.Name -match "_dmarc"}).Strings
            Write-LogInfo "$Domain : Check DMARC - $DMARCResultesStrings"
        }
          }
}


Function Start-DKIMConfig {
     <#
        .Synopsis
         Check and extract DKIM configuration 
        
        .Description
         This function will check and extract DKIM configuration

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
    [String]$Name = "DKIM Configuration"
)

#SCRIPT DKIM

$Domains=(Get-AcceptedDomain | Where-Object { $_.DomainName -notmatch "onmicrosoft.com"}).Name
$DKIMResults = @()
foreach ($Domain in $Domains){

                             if (!(Get-DkimSigningConfig -Identity $domain -ErrorAction SilentlyContinue)){
                                $exportconfig = $true
                                New-DkimSigningConfig -DomainName $Domain -Enabled $false
                                Write-LogInfo "$Domain : Setting DKIM configuration"
                                Write-LogInfo "$Domain : Please get file csv in folder .\Output and insert records in Domain Registrar"
                                }
                                else {
                             if ((Get-DkimSigningConfig -Identity $Domain).Status -eq "Valid"){
                                Write-LogInfo "$Domain : DKIM Config is OK - No action necessary"
                                }
                                if ((Get-DkimSigningConfig -Identity $Domain).Status -eq "CnameMissing"){
                                      $DKIMResults += $Domain
                                      } 
                                }
                                }
                                
                             if ($DKIMResults -ne $null){
                                $exportconfig = $true
                                Write-LogWarning "Please get file csv in folder .\Output and insert records in Domain Registrar for $DKIMResults"
                                }
                                

                    if ($exportconfig -eq $true) {
                    mkdir -Force ".\Output" | Out-Null
                    $DKIMRecords=(Get-DkimSigningConfig | Where-Object { $_.Identity -notmatch "onmicrosoft.com"} | Select-object Domain,Selector1CNAME,Selector2CNAME)
                    $Export = foreach ($DKIMRecords in $DKIMRecords) {
                    [PSCustomObject]@{
                    CNAME1 = -join("selector1._domainkey.",$DKIMRecords.Domain)
                    Value1 = $DKIMRecords.Selector1CNAME
                    CNAME2 = -join("selector2._domainkey.",$DKIMRecords.Domain)
                    Value2 = $DKIMRecords.Selector2CNAME
                    }
                    }
                    $Export | Select-object "CNAME1","Value1","CNAME2","Value2" | Export-Csv -Path `.\Output\DNSRecord_DKIM.csv -Delimiter ';' -Encoding UTF8 -NoTypeInformation
                    }
          

#SCRIPT DMARC
$DMARCRecords = @{}
foreach ($Domain in $Domains) {
    $DMARCResultes = Resolve-DnsName -Type Txt -Name _dmarc.$Domain -erroraction 'silentlycontinue'
        If ($DMARCResultes -eq $Null){
            $exportcsvdmarc = $true
            Write-LogInfo "$Domain : No DMARC - Export csv"
            Write-LogWarning "$Domain : Please get file csv in folder .\Output and insert records in Domain Registrar"
            $DMARCRecords.Add("_dmarc.$Domain","v=DMARC1; p=none; pct=100; rua=mailto:d@$Domain; ruf=mailto:d@$Domain; fo=1")
                        }
        }
if ($exportcsvdmarc -eq $true) {
mkdir -Force ".\Output" | Out-Null
$DMARCRecords.keys | Select @{l='Record';e={$_}},@{l='Value';e={$DMARCRecords.$_}} | Export-Csv -Path `.\Output\DNSRecord_DMARC.csv -Delimiter ';' -Encoding UTF8 -NoTypeInformation}
else {
Write-LogInfo "$Domain : DMARC - Already created"}
        
}


Function Start-DKIMConfigEnable {
     <#
        .Synopsis
         Enable and configure DKIM 
        
        .Description
         This function will Verify, extract and configure DKIM 

        .Notes
         Version: 01.00 -- 
         
    #>

	param(
	[Parameter(Mandatory = $false)]
    [String]$Name = "DKIM Configuration"
)

#SCRIPT ENABLE DKIM
$Domains=(Get-AcceptedDomain | Where-Object { $_.DomainName -notmatch "onmicrosoft.com"}).Name
$DKIMResults = @()
foreach ($Domain in $Domains){
            $DKIMResultes = Resolve-DnsName -Type CNAME -Name selector1._domainkey.$Domain -erroraction 'silentlycontinue'
            if (-not $DKIMResultes){
            $DKIMResults += $Domain
            }
            elseif (((Get-DkimSigningConfig -Identity $Domain).Status -eq "CnameMissing") -and ((Get-DkimSigningConfig -Identity $Domain).Enabled -eq $false)) {
                    Set-DkimSigningConfig -Identity $Domain -Enabled $true | Out-Null
                    Write-LogInfo "$Domain : DKIM Enabled"
                    } 
                  }
            if ($DKIMResults -ne $null){
            Write-LogWarning "Please get file csv in folder .\Output and insert records in Domain Registrar for $DKIMResults"
            }

#SCRIPT DKIM 2048 KEYSIZE
foreach ($Domain in $Domains) {
      if (((Get-DkimSigningConfig -Identity $Domain).Selector1KeySize -eq "1024") -and ((Get-DkimSigningConfig -Identity $Domain).Enabled -eq $true)) {
      Rotate-DkimSigningConfig -KeySize 2048 -Identity $Domain | Out-Null
      Write-LogInfo "$Domain : DKIM Config changed with keysize 2048"}
      }
                    
 Write-LogSection '' -NoHostOutput  

}






