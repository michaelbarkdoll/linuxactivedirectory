#
# Determines if a computer exists at a particular Organization Unit inside Active Directory and removes it
#
# Script requires two arguments:
# arg1: computerName (e.g., CS-533791)
# arg2: SearchBase (e.g., "ou=Sample,dc=controller,dc=domain,dc=edu")

import-module activedirectory

$servername=$args[0]
$searchbase=$args[1]

function Test-InSearchBase {
    param (
        [string]$DistinguishedName,
        [string]$SearchBase
    )

    if ([string]::IsNullOrWhiteSpace($DistinguishedName) -or [string]::IsNullOrWhiteSpace($SearchBase)) {
        return $false
    }

    return $DistinguishedName.ToLower().EndsWith("," + $SearchBase.ToLower())
}

function Format-DistinguishedNames {
    param (
        [object[]]$Computers
    )

    return (($Computers | ForEach-Object { $_.DistinguishedName }) -join "|")
}

try {
    $matches = @(Get-ADComputer -Filter "Name -eq '${servername}'" -Properties DistinguishedName -ErrorAction Stop)
}
catch {
    $matches = @()
}

if ($matches.Count -eq 0) {
    Write-Host "none"
    exit 0
}

if ($matches.Count -gt 1) {
    Write-Host "multiple_matches:$((Format-DistinguishedNames -Computers $matches))"
    exit 0
}

$target = $matches[0]

if (-not (Test-InSearchBase -DistinguishedName $target.DistinguishedName -SearchBase $searchbase)) {
    Write-Host "exists_in_other_ou:$($target.DistinguishedName)"
    exit 0
}

try {
    Remove-ADComputer -Identity $target.DistinguishedName -Confirm:$False -ErrorAction Stop
}
catch {
    try {
        $childObjects = @(Get-ADObject -Filter * -SearchBase $target.DistinguishedName -ErrorAction Stop | Where-Object { $_.ObjectClass -eq "msFVE-RecoveryInformation" })
        if ($childObjects.Count -gt 0) {
            $childObjects | ForEach-Object {
                Remove-ADObject $_ -Confirm:$False -ErrorAction Stop
            }
            Remove-ADComputer -Identity $target.DistinguishedName -Confirm:$False -ErrorAction Stop
        }
        else {
            throw
        }
    }
    catch {
        $message = $_.Exception.Message -replace "[\r\n]+", " "
        Write-Host "error:$message"
        exit 0
    }
}

try {
    $remaining = @(Get-ADComputer -Filter "Name -eq '${servername}'" -Properties DistinguishedName -ErrorAction Stop)
}
catch {
    $remaining = @()
}

if ($remaining.Count -eq 0) {
    Write-Host "removed"
}
elseif ($remaining.Count -eq 1) {
    Write-Host "error:still_exists:$($remaining[0].DistinguishedName)"
}
else {
    Write-Host "error:multiple_remaining:$((Format-DistinguishedNames -Computers $remaining))"
}
