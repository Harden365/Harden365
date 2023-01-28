<# 
    .NOTES
    ===========================================================================
        FileName:     Harden365.Teams.psm1
        Author:       Community Harden - contact@harden365.net
        Created On:   09/28/2021
        Last Updated: 12/02/2021
        Version:      v0.7
    ===========================================================================

    .SYNOPSYS
        Hardening Teams Environnement

    .DESCRIPTION
        Configure which users are allowed to present in Teams meetings
        Only invited users should be automatically admitted to Teams meetings
        Restrict Anonymous to join meeting
        Confirm Modern Auth activation
        Block file sharing for other cloud storage services

#>

Function Start-TeamsAdalAuthOverride {
    <#
        .Synopsis
         Confirm Modern Auth activation
        
        .Description
         Confirm Modern Auth activation

        .Notes
         Version: 01.00 -- 
         
    #>

    Write-LogSection 'MICROSOFT TEAMS' -NoHostOutput

    #SCRIPT
    if ($(Get-CsOAuthConfiguration).ClientAdalAuthOverride -eq 'Disallowed') { 
        Write-LogWarning 'Modern Auth in Teams is disable!'
        Set-CsOAuthConfiguration -ClientAdalAuthOverride Allowed
        Write-LogInfo 'Modern Auth in Teams set to enable'
    }
    else {
        Write-LogInfo 'Modern Auth in Teams enabled'
    }
    
}

Function Start-TeamsAutoAdmitUsers {
    <#
        .Synopsis
         Only invited users should be automatically admitted to Teams meetings
        
        .Description
         Only invited users should be automatically admitted to Teams meetings

        .Notes
         Version: 01.00 -- 
         
    #>

    #SCRIPT
    if ((Get-CsTeamsMeetingPolicy -Identity Global).AutoAdmittedUsers -ne 'InvitedUsers') {
        Set-CsTeamsMeetingPolicy -Identity Global -AutoAdmittedUsers InvitedUsers
        Write-LogInfo 'AutoAdmittedUsers change at InvitedUsers' 
    }
    else {
        Write-LogInfo 'AutoAdmittedUsers configured for InvitedUsers'
    }     
}

Function Start-TeamsBlockAnonymousJoin {
    <#
        .Synopsis
         Restrict Anonymous to join meeting
        
        .Description
         Restrict Anonymous to join meeting

        .Notes
         Version: 01.00 -- 
         
    #>

    #SCRIPT
    if ((Get-CsTeamsMeetingPolicy -Identity Global).AllowAnonymousUsersToJoinMeeting -eq $true) {
        Set-CsTeamsMeetingPolicy -Identity Global -AllowAnonymousUsersToJoinMeeting $false
        Write-LogInfo 'Block Anonymous Users To Join Meeting' 
    }
    else {
        Write-LogInfo 'Anonymous Users already disabled To Join Meeting'
    }
      
}

Function Start-TeamsBlockStorageCloudServices {
    <#
        .Synopsis
         Block file sharing for other cloud storage services
        
        .Description
         Ensure external file sharing in Teams is enabled for only approved cloud storage services

        .Notes
         Version: 01.00 -- 
         
    #>

    param(
        [Parameter(Mandatory = $false)]
        [Boolean]$DropBox = $false,
        [Boolean]$Box = $false,
        [Boolean]$GoogleDrive = $false,
        [Boolean]$ShareFile = $false,
        [Boolean]$Egnyte = $false
    )


    #SCRIPT
    if (($DropBox -eq $false) -and (Get-CsTeamsClientConfiguration).AllowDropBox -eq $true) { 
        Write-LogWarning 'DropBox allowed in Teams !'
        Set-CsTeamsClientConfiguration -AllowDropBox $DropBox
        Write-LogInfo 'DropBox disabled in Teams !'
    }
    else {
        Write-LogInfo 'DropBox already disabled in Teams'
    }
    if (($Box -eq $false) -and (Get-CsTeamsClientConfiguration).AllowBox -eq $true) { 
        Write-LogWarning 'Box allowed in Teams !'
        Set-CsTeamsClientConfiguration -AllowBox $Box
        Write-LogInfo 'Box disabled in Teams !'
    }
    else {
        Write-LogInfo 'Box already disabled in Teams'
    }
    if (($GoogleDrive -eq $false) -and (Get-CsTeamsClientConfiguration).AllowGoogleDrive -eq $true) { 
        Write-LogWarning 'GoogleDrive allowed in Teams !'
        Set-CsTeamsClientConfiguration -AllowGoogleDrive $GoogleDrive
        Write-LogInfo 'GoogleDrive disabled in Teams !'
    }
    else {
        Write-LogInfo 'GoogleDrive already disabled in Teams'
    }
    if (($ShareFile -eq $false) -and (Get-CsTeamsClientConfiguration).AllowShareFile -eq $true) { 
        Write-LogWarning 'ShareFile allowed in Teams !'
        Set-CsTeamsClientConfiguration -AllowShareFile $ShareFile
        Write-LogInfo 'ShareFile disabled in Teams !'
    }
    else {
        Write-LogInfo 'Sharefile already disabled in Teams'
    }
    if (($Egnyte -eq $false) -and (Get-CsTeamsClientConfiguration).AllowEgnyte -eq $true) { 
        Write-LogWarning 'Egnyte allowed in Teams !'
        Set-CsTeamsClientConfiguration -AllowEgnyte $Egnyte
        Write-LogInfo 'Egnyte disabled in Teams !'
    }
    else {
        Write-LogInfo 'Egnyte already disabled in Teams'
    }
     
}

Function Start-TeamsPresentMeet {
    <#
        .Synopsis
         Configure which users are allowed to present in Teams meetings
        
        .Description
         Configure which users are allowed to present in Teams meetings

        .Notes
         Version: 01.00 -- 
         
    #>



    #SCRIPT
    if ((Get-CsTeamsMeetingPolicy -Identity Global).DesignatedPresenterRoleMode -ne 'OrganizerOnlyUserOverride') {
        Set-CsTeamsMeetingPolicy -Identity Global -DesignatedPresenterRoleMode OrganizerOnlyUserOverride
        Write-LogInfo 'DesignatedPresentaterRoleMode change at OrganizerOnlyUserOverride' 
    }
    else {
        Write-LogInfo 'DesignatedPresentaterRoleMode already set at OrganizerOnlyUserOverride'
    }
    Write-LogSection '' -NoHostOutput         
}

Function Start-TeamsExternalControl {
    <#
        .Synopsis
         Configure which users are allowed to present in Teams meetings
        
        .Description
         Configure which users are allowed to present in Teams meetings

        .Notes
         Version: 01.00 -- 
         
    #>



    #SCRIPT
    if ((Get-CsTeamsMeetingPolicy -Identity Global).AllowExternalParticipantGiveRequestControl -ne $false) {
        Set-CsTeamsMeetingPolicy -Identity Global -AllowExternalParticipantGiveRequestControl $false
        Write-LogInfo 'AllowExternalParticipantGiveRequestControl disabled' 
    }
    else {
        Write-LogInfo 'AllowExternalParticipantGiveRequestControl already disabled'
    }
    Write-LogSection '' -NoHostOutput         
}

