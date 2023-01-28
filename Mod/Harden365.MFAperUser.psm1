<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.MFAperUser.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 01/18/2021
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening MFA per User

    .DESCRIPTION
        Import csv for activate MFA by SMS
#>


Function Start-LegacyPerUserMFA {
    <#
        .Synopsis
         Import csv for activate MFA by SMS.
        
        .Description
         This function will import phone number for activate MFA by SMS token .
        
        .Notes
         Version: 01.00 -- 
         
    #>


    param(
        [Parameter(Mandatory = $false)]
        [String]$Name = 'Legacy MFA per User Activation',
        [String]$ImportCSV = 'ImportPhoneNumbers.csv',
        [String]$UPN = ''
    )


    Write-LogSection 'MFA PER USER' -NoHostOutput


    #SCRIPT

    Write-LogInfo "Import CSV File : $ImportCSV"

    Try {
        Import-Csv ".\Input\$ImportCSV" -Delimiter ';' | ForEach-Object {
            if ($_.ImportPhoneNumber -eq 'YES') {
                $Requirements = @()
                if ($State -ne 'Disabled') {
                    $Requirement = [Microsoft.Online.Administration.StrongAuthenticationRequirement]::new()
                    $Requirement.RelyingParty = '*'
                    $Requirement.State = 'Enabled'
                    $Requirements += $Requirement
                }
                Set-MsolUser -UserPrincipalName $_.UserPrincipalName -StrongAuthenticationRequirements $Requirements
                Write-LogInfo "$($_.UserPrincipalName) : PhoneNumber $($_.PhoneNumbers) added"
            }
            else {
                Write-LogError "$($_.UserPrincipalName) : MFA not activated !" 
            }
        }
    }
    catch {
        Write-LogError "$($_.UserPrincipalName) : MFA ERROR !" 
    }

    Write-LogSection '' -NoHostOutput

}