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
        $output = New-ADComputer -Name "${server}" -SamAccountName "${server}" -Path "${searchbase}"
        if ($?) {
            Write-Host "created"
        }
        else {
            Write-Host "exists"  
        }
    }
    catch{
        Write-Host "exists"
    }
}