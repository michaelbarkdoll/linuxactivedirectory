#
# Determines if a computer exists at a particular Organization Unit inside Active Directory
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

if ($matches.Count -gt 1) {
    Write-Host "multiple_matches:$((Format-DistinguishedNames -Computers $matches))"
    exit 0
}

if ($matches.Count -eq 1) {
    if (Test-InSearchBase -DistinguishedName $matches[0].DistinguishedName -SearchBase $searchbase) {
        Write-Host "exists_in_ou"
    }
    else {
        Write-Host "exists_in_other_ou:$($matches[0].DistinguishedName)"
    }
    exit 0
}

try {
    New-ADComputer -Name "${servername}" -SamAccountName "${servername}" -Path "${searchbase}" -ErrorAction Stop | Out-Null
    $createdObject = Get-ADComputer -Filter "Name -eq '${servername}'" -SearchBase $searchbase -Properties DistinguishedName -ErrorAction Stop
    if ($null -ne $createdObject) {
        Write-Host "created"
    }
    else {
        Write-Host "error:verification_failed"
    }
}
catch {
    $message = $_.Exception.Message -replace "[\r\n]+", " "
    Write-Host "error:$message"
}
