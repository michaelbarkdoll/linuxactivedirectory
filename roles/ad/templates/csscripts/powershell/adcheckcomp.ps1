#
# Determines if a computer exists at a particular Organization Unit inside Active Directory
#
# Script requires two arguments:
# arg1: computerName (e.g., CS-533791)
# arg2: SearchBase (e.g., "ou=Sample,dc=controller,dc=domain,dc=edu")

import-module activedirectory

$servername=$args[0]
$searchbase=$args[1]

$serverlist = @(
    $servername
)

foreach ($server in $serverlist) {
    try{
        $output = Get-ADComputer -Filter "Name -eq '${server}'" -SearchBase $searchbase
        if ($output -eq $Null) {
            Write-Host "none"
        }
        else {
            Write-Host "exists"  
        }
    }
    catch{
        Write-Host "none"
    }
}