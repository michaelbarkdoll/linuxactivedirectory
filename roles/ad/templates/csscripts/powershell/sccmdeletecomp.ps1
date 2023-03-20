#
# Determines if a computer exists at a particular Organization Unit inside Active Directory
#
# Script requires two arguments:
# arg1: computerName (e.g., CS-533791)
# arg2: SearchBase (e.g., "ou=Sample,dc=controller,dc=domain,dc=edu")

#import-module activedirectory

#PS C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin> Import-Module .\ConfigurationManager.psd1
Import-Module "C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"
cd PS2:

$computername=$args[0]

Import-Module ConfigurationManager
#Connect-CMServer -SiteServer itsys-sccm.ad.siu.edu
#$device = Get-CMDevice -Name "CS-533105"
$device = Get-CMDevice -Name "$computername"
if ($device) {
    Write-Host "Device exists is in SCCM."
    Remove-CMDevice -Name "$computername" -Force
    if ($? -ne True) {
        Write-Host "Failed to delete object in SCCM."
    }
} else {
    Write-Host "Device is not in SCCM."
}
