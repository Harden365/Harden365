$ApplicationID = "169b6f07-ed36-4be5-af31-1aaf86298b21"
$TenantDomainName = "a4755b03-eb06-4ba6-977c-756caf25aff1"
$AccessSecret = "ZGM1ODY4NjEtNjJhYy00ZmQyLWI4ZTYtYTVjNDA0Y2VhYmM1"

$Body = @{
Grant_Type    = "client_credentials"
Scope         = "https://graph.microsoft.com/.default"
client_Id     = $ApplicationID
Client_Secret = $AccessSecret
}
$ConnectGraph = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantDomainName/oauth2/v2.0/token -Method POST -Body $Body
$token = $ConnectGraph.access_token

$GrapGroupUrl = 'https://graph.microsoft.com/v1.0/Groups/'
$Groups=(Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)"} -Uri $GrapGroupUrl -Method Get).value
$Groups | select displayName,createdDateTime