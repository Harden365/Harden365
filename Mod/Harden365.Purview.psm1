﻿

Connect-AzureAD


# POWERSHELL https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/groups-settings-cmdlets
$TemplateId = (Get-AzureADDirectorySettingTemplate | Where-Object { $_.DisplayName -eq 'Group.Unified' }).Id
$Template = Get-AzureADDirectorySettingTemplate | Where-Object -Property Id -Value $TemplateId -EQ
$Setting = $Template.CreateDirectorySetting()
$Setting['EnableMIPLabels'] = 'True'
New-AzureADDirectorySetting -DirectorySetting $Setting


$grpUnifiedSetting = (Get-AzureADDirectorySetting | Where-Object -Property DisplayName -Value 'Group.Unified' -EQ)
$Setting = $grpUnifiedSetting
if ($grpUnifiedSetting.Values -eq $null) {
    $Setting['EnableMIPLabels'] = 'True'
}
Set-AzureADDirectorySetting -Id $grpUnifiedSetting.Id -DirectorySetting $Setting


# sync label with AAD
Execute-AzureAdLabelSync