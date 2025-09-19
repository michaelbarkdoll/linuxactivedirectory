<#!
Usage:
  adsetpasswdcomp.ps1 <ComputerName> "<OU DN>" [OneTimePassword] [EncTypes]

Examples:
  # Uses the default password "MyOneTimeJoinPassw0rd!"
  adsetpasswdcomp.ps1 CS-539303 "OU=...Academic Affairs,DC=ad,DC=siu,DC=edu"

  # Override with custom password
  adsetpasswdcomp.ps1 CS-539303 "OU=...Academic Affairs,DC=ad,DC=siu,DC=edu" "CustomPass123!"

  # Override password and enc types
  adsetpasswdcomp.ps1 CS-539303 "OU=...Academic Affairs,DC=ad,DC=siu,DC=edu" "CustomPass123!" 24
#>

param(
  [Parameter(Mandatory=$true)][string]$ComputerName,
  [Parameter(Mandatory=$true)][string]$SearchBase,
  [string]$OneTimePass = "MyOneTimeJoinPassw0rd!",
  [int]$EncTypes = 28   # 24 = AES only, 28 = AES+RC4
)

$ErrorActionPreference = 'Stop'

try {
  Import-Module ActiveDirectory -ErrorAction Stop

  # Look for existing computer
  $comp = Get-ADComputer -Filter 'Name -eq $ComputerName' -SearchBase $SearchBase -Properties DistinguishedName -ErrorAction SilentlyContinue

  $result = 'exists'
  if (-not $comp) {
    $comp = New-ADComputer -Name $ComputerName `
                           -SamAccountName ("{0}$" -f $ComputerName) `
                           -Path $SearchBase `
                           -Enabled $true `
                           -OtherAttributes @{ 'msDS-SupportedEncryptionTypes' = $EncTypes }
    $result = 'created'
  } else {
    Enable-ADAccount -Identity $comp.DistinguishedName | Out-Null
    Set-ADComputer -Identity $comp.DistinguishedName -Replace @{ 'msDS-SupportedEncryptionTypes' = $EncTypes }
    $result = 'updated'
  }

  # Set/reset the one-time password
  $sec = ConvertTo-SecureString -String $OneTimePass -AsPlainText -Force
  Set-ADAccountPassword -Identity $comp.DistinguishedName -Reset -NewPassword $sec

  # Confirm
  $comp2 = Get-ADComputer -Identity $comp.DistinguishedName -Properties msDS-SupportedEncryptionTypes,Enabled

  Write-Output ("status={0} dn=""{1}"" enabled={2} enctypes={3} password=""{4}""" -f `
     $result, $comp2.DistinguishedName, $comp2.Enabled, $comp2.'msDS-SupportedEncryptionTypes', $OneTimePass)

  exit 0
}
catch {
  $msg = ($_ | Out-String).Trim() -replace '\s+',' '
  Write-Output ("error=true message=""{0}""" -f $msg)
  exit 1
}
