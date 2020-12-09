# get all possible(?) Azure AD Application permissions in a given tenant with ID and Name and write them to a csv
# author: @janvonkirchheim

$a.clear()
$a=@{}
$spAll = Get-AzureADServicePrincipal -All $true 
foreach ($sp in $spAll)
{
    foreach($g in $sp.AppRoles)
    {
        $a.add($g.id,$g.value)
    }
}
$a.GetEnumerator() | Select-Object -Property key,value | Export-Csv -Path aadAppPermissions.csv
