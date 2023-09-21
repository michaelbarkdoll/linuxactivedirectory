#
# Determines if a computer exists at a particular Organization Unit inside Active Directory and removes it
#
# Script requires two arguments:
# arg1: computerName (e.g., CS-533791)
# arg2: SearchBase (e.g., "ou=Sample,dc=controller,dc=domain,dc=edu")

import-module activedirectory

$servername=$args[0]
$searchbase=$args[1]

#$servername="CS-537982"
#$searchbase="ou=A410,ou=Linux Labs,ou=Computers,ou=CS,ou=COS,ou=Academic Affairs,dc=ad,dc=domain,dc=edu"

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
            try {
                $output = Get-ADComputer -Filter "Name -eq '${server}'" -SearchBase $searchbase | Remove-ADComputer -Confirm:$False -ErrorAction Stop
                if ($?) 
                {
                    Write-Host "removed"  
                }
            }
            catch {
                #Write-Host "In catch loop"
                # Check for Bitlocker recovery information child objects if deletion failed
                $computerDN = $output.DistinguishedName
                #Get-ADObject -Filter * -SearchBase $computerDN | Select-Object Name, ObjectClass

                #$allchildObjects = Get-ADObject -Filter * -SearchBase $computerDN
                $childObjects = Get-ADObject -Filter * -SearchBase $computerDN | Where-Object { $_.ObjectClass -eq "msFVE-RecoveryInformation" }

                
                if ($childObjects) {
                    # Delete Bitlocker recovery information objects
                    $childObjects | ForEach-Object {
                        Remove-ADObject $_ -Confirm:$false
                    }

                    # Attempt to remove the computer object again
                    $output | Remove-ADComputer -Confirm:$False
                    if ($?) {
                        Write-Host "removed"
                    } else {
                        Write-Host "error"
                    }
                }
                else {
                    Write-Host "error"
                }
            }
        }
    }
    catch{
        Write-Host "none"
    }
}