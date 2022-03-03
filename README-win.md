# Setup ssh server access on a windows machine joined to active directory

https://docs.ansible.com/ansible/latest/user_guide/windows_setup.html
https://github.com/PowerShell/Win32-OpenSSH/wiki/Install-Win32-OpenSSH


Download the latest build of OpenSSH.
https://github.com/PowerShell/Win32-OpenSSH/releases/latest
https://github.com/PowerShell/Win32-OpenSSH/wiki/How-to-retrieve-links-to-latest-packages
```
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$url = 'https://github.com/PowerShell/Win32-OpenSSH/releases/latest/'
$request = [System.Net.WebRequest]::Create($url)
$request.AllowAutoRedirect=$false
$response=$request.GetResponse()
$([String]$response.GetResponseHeader("Location")).Replace('tag','download') + '/OpenSSH-Win64.zip'  
$([String]$response.GetResponseHeader("Location")).Replace('tag','download') + '/OpenSSH-Win32.zip'
```

Extract contents of the latest build to C:\Program Files\OpenSSH (Make sure binary location has the Write permissions to just to SYSTEM, Administrator groups. Authenticated users should and only have Read and Execute.)

In an elevated Powershell console, run the following:
```
cd C:\Program Files\OpenSSH
powershell.exe -ExecutionPolicy Bypass -File install-sshd.ps1
```

Open the firewall for sshd.exe to allow inbound SSH connections

Windows Server 2012 and above:
```
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

Windows 10 Desktop or newer:
```
netsh advfirewall firewall add rule name=sshd dir=in action=allow protocol=TCP localport=22
```

Start sshd (this will automatically generate host keys under %programdata%\ssh if they don't already exist)
```
net start sshd
```

Powershell cmdlets to set powershell bash as default shell instead of command prompt:
```
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShellCommandOption -Value "/c" -PropertyType String -Force
```

To setup sshd service to auto-start
```
Set-Service sshd -StartupType Automatic
```


https://github.com/PowerShell/Win32-OpenSSH/wiki/sshd_config

The allow/deny directives are processed in the following order: DenyUsers, AllowUsers, DenyGroups, and finally AllowGroups.


Restrict ssh access to various domain user accounts via Powershell:
```
$aduser = "aduser"
$searchText = "AllowUsers DOMIAN\\$aduser"
$file = Get-ChildItem $env:PROGRAMDATA\ssh\sshd_config
$result = Select-String -Quiet -Pattern "^$searchText" -Path $file
if (-not $result) { Add-Content -Path $file -Value "AllowUsers DOMAIN\$aduser" }
```


Limit logins over ssh using bash via WSL:
Edit %programdata%\ssh\sshd_config
```
ssh aduser@192.168.x.x
powershell
cd C:\ProgramData\ssh\sshd_config
bash -c "vi sshd_config"
```

```
AllowUsers DOMAIN\aduser
AllowUsers DOMAIN\aduser2
```

```
Restart-Service sshd
```


Match Group administrators
       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys

Add ssh key to administrators authorized keys
```
cat ~/.ssh/id_rsa.pub
# Note: this is <PUBLIC_KEY> used below
```

```
$aduserpubkey = "<PUBLIC_KEY>"
$searchText = "$aduserpubkey"
$file = Get-ChildItem $env:PROGRAMDATA\ssh\administrators_authorized_keys
$result = Select-String -Quiet -Pattern "^$searchText" -Path $file
if (-not $result) { Add-Content -Path $file -Value "$aduserpubkey" }
```