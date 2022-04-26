Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)

$SiteCode = Get-PSDrive -PSProvider CMSITE
Set-Location -Path "$($SiteCode.Name):\"

$servername=$args[0]
$searchbase=$args[1]

$serverlist = @(
    $servername
)

foreach ($server in $serverlist) {

    try{
        $CN = Get-CMDevice -Name "${server}"
        $name = $CN.Name

        if ($name -eq $Null) {
            Write-Host "none"
        }
        else {
            try {
                Remove-CMDevice -name $server -force 
                if ($?) 
                {
                    Write-Host "removed"  
                }
                else 
                {
                    Write-Host "error"  
                }
            }
            catch {
            }
        }
    }
    catch{
        Write-Host "none"
    }
}