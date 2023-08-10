<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.PowerPlatform.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   05/06/2022
        Last Updated: 05/06/2022
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening PowerPlatform

    .DESCRIPTION
        Disable User to share Apps to everyone.
        Disable subscription free licence by users.
        Disable subscription payable licence by users.
        Disable subscription trial/developer licence by users.

#>

Function Start-BlockShareAppsEveryone {
     <#
        .Synopsis
         Disable User to share Apps to everyone.
        
        .Description
         Disable User to share Apps to everyone.

        .Notes
         Version: 01.00 -- 
         
    #>

    Param(
        
    )

Write-LogSection 'POWERPLATFORM' -NoHostOutput

#SCRIPT
try {
Get-TenantSettings | Out-Null }
catch {}
if ((Get-TenantSettings).powerPlatform.powerApps.disableShareWithEveryone -eq $false) {
    Write-LogWarning "User allow to share apps with everyone"
    $settings = Get-TenantSettings
    $settings.powerPlatform.powerApps.disableShareWithEveryone=$true
    Set-TenantSettings $settings
    Write-LogInfo "Disable standard users to share apps with everyone"}
else {Write-LogInfo "Standard users already disabled to share apps with everyone $upn"}
}

Function Start-BlockSubscriptionFree {
     <#
        .Synopsis
         Disable subscription free licence by users.
        
        .Description
         Disable subscription free licence by userA.

        .Notes
         Version: 01.00 -- 
         
    #>


#SCRIPT
if ((Get-MsolCompanyInformation).AllowAdHocSubscriptions -eq $true) {
    Write-LogWarning "Prevent standard users from creating free subscriptions"
    Set-MsolCompanySettings -AllowAdHocSubscriptions $false
    Write-LogInfo "Disable standard users from creating free subscriptions"}
else {Write-LogInfo "Standard users already disabled to create free subscriptions"}
}

Function Start-BlockSubscriptionPayable {
     <#
        .Synopsis
         Disable subscription payable licence by users.
        
        .Description
         Disable subscription payable licence by userA.

        .Notes
         Version: 01.00 -- 
         
    #>


#SCRIPT
Connect-MSCommerce
$Products = Get-MSCommerceProductPolicies -PolicyId AllowSelfServicePurchase
ForEach ($Product in $Products) {
        $productName = $Product.ProductName
    if ($Product.PolicyValue -eq "Enabled") {
        Write-LogWarning "Prevent standard users from creating $ProductName payable subscriptions"
        Update-MSCommerceProductPolicy -PolicyId AllowSelfServicePurchase -ProductId $Product.ProductId -Enabled $false | Out-Null
        Write-LogInfo "Disable standard users from creating $ProductName payable subscriptions"}
    else {Write-LogInfo "Standard users already disabled to subscribe $ProductName payable subscriptions"}
    }
}

Function Start-BlockSubscriptionTrials {
     <#
        .Synopsis
         Disable subscription trial/developer licence by users.
        
        .Description
         Disable subscription trial/developer licence by userA.

        .Notes
         Version: 01.00 -- 
         
    #>

        Param(
        
    )

#SCRIPT
if (((Get-AllowedConsentPlans).Types -eq "Internal") -or ((Get-AllowedConsentPlans).Types -eq "Viral")) {
    Write-LogWarning "Prevent standard users from creating trial/developer subscriptions"
    Remove-AllowedConsentPlans -Types @("Internal", "Viral") -Prompt $false
    Write-LogInfo "Disable standard users from creating trial/developer subscriptions"}
else {Write-LogInfo "Standard users already disabled to create trial/developer subscriptions"}

Write-LogSection '' -NoHostOutput

}

