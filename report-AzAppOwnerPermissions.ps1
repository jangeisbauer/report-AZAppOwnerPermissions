# report-AzAppOwnerPermissions.ps1
# author: Jan Geisbauer (@janvonkirchheim)
# connect to AzureAD first

$all=@()
$azApps = Get-AzureADApplication -All $true
$spAll = Get-AzureADServicePrincipal -All $true 
foreach($azApp in $azApps)
{
    $appOwners = $null
    $appOwners = get-azureadApplicationowner -objectid $azApp.objectid
    
    $permissions=@()
    
    if($null -ne $appOwners)
    {
        $strAppOwner = ""
        foreach($appOwner in $appOwners)
        {
            $strAppOwner += $appOwner.displayname + " (" + $appOwner.userprincipalname + ") "
        }
        
        #Required Resource Access
        $ResAccess=$azApp.RequiredResourceAccess | ConvertTo-Json -Depth 3 | convertfrom-json
        foreach($ra in $resAccess)
        {
            #App has access to these single (access) resources
            foreach($access in $ra.resourceaccess)
            {
                $sp = $spAll | Where-Object {$_.AppId -eq $ra.ResourceAppId}
                # APP Permissions
                if($access.type -eq "Role")
                {
                    $spAppRoles = $sp.AppRoles | Where-Object {$_.Id -eq $access.Id}
                    foreach($spAppRole in $spAppRoles)
                    {
                        $permissions += "(APP-Perm) " + $sp.displayname + ": " + $spAppRole.Value
                    }
                }
                # Delegate Permissions ("Scope")
                else {
                    $spOauthPerm = $sp.Oauth2Permissions | Where-Object {$_.Id -eq $access.Id}
                    foreach($spAppRole in $spAppRoles)
                    {
                        $permissions += "(DEL-Perm) " + $sp.displayname + ": " + $spOauthPerm.Value
                    }
                }
            }
        }          
    }
    # PS Object is not really needed at the moment 
    if($permissions.length -ne 0)
    {
        $PSAppOwner = new-object psobject
        $PSAppOwner | Add-Member NoteProperty AppName  $azApp.displayname
        $PSAppOwner | Add-Member NoteProperty AppRoles $permissions
        $PSAppOwner | Add-Member NoteProperty AppOwner $strAppOwner 
        $all += $PSAppOwner
    }
}
$csv=@()
foreach($line in $all)
{
    $perm = $line | Select-Object -ExpandProperty AppRoles
    foreach($p in $perm)
    {
        $csv+=$line.AppName + ";" + $line.AppOwner + ";"+ $p
    }
}
$csv | add-content -path AzAppOwnerPermissions.csv
