A) Install & start (prefer inbox OpenSSH on Win11)

```
# Run in elevated PowerShell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service sshd -StartupType Automatic

# If you need a firewall rule manually (often not necessary on Win11):
New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)'
  -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

B) Set PowerShell as the default shell (PowerShell 5.1)
```
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell `
  -Value 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' `
  -PropertyType String -Force
Restart-Service sshd
```

If using PowerShell 7, either point DefaultShell to pwsh.exe or add a Subsystem powershell line in sshd_config as noted above.

C) Idempotently restrict logins with AllowUsers
```
# Variables
$aduser = 'aduser'
$line   = "AllowUsers DOMAIN\$aduser"
$path   = Join-Path $env:PROGRAMDATA 'ssh\sshd_config'

# Ensure file exists
if (-not (Test-Path $path)) { New-Item -Path $path -ItemType File -Force | Out-Null }

# Append only if not present (literal match)
$present = Select-String -Path $path -Pattern $line -SimpleMatch -Quiet
if (-not $present) {
    Add-Content -Path $path -Value ($line + "`r`n")
    Restart-Service sshd
}
```

If you want multiple users, manage one line that lists them all (OpenSSH parses space-separated names):
```
$users = @('DOMAIN\aduser','DOMAIN\aduser2','DOMAIN\aduser3') -join ' '
$line  = "AllowUsers $users"
# (same append logic as above; replace on change if you want strict control)
```

D) Add key to administrators_authorized_keys (admins only)
```
# --- CONFIGURE THIS ---
$aduserpubkey = 'ssh-ed25519 AAAA... your_key_here ... comment'

# Paths
$programDataSsh = Join-Path $env:PROGRAMDATA 'ssh'
$filePath       = Join-Path $programDataSsh 'administrators_authorized_keys'

# Ensure folder/file
if (-not (Test-Path $programDataSsh)) { New-Item -Path $programDataSsh -ItemType Directory -Force | Out-Null }
if (-not (Test-Path $filePath))       { New-Item -Path $filePath       -ItemType File      -Force | Out-Null }

# Lock down ACLs
icacls $filePath /inheritance:r | Out-Null
icacls $filePath /grant:r "SYSTEM:(F)" "BUILTIN\Administrators:(F)" | Out-Null
icacls $filePath /remove:g "Users" "Authenticated Users" 2>$null | Out-Null
# Optional: enforce owner
try { icacls $filePath /setowner "BUILTIN\Administrators" | Out-Null } catch {}

# Append key if missing (literal match)
$exists = Select-String -Path $filePath -Pattern $aduserpubkey -SimpleMatch -Quiet
if (-not $exists) {
    Add-Content -Path $filePath -Value ($aduserpubkey + "`r`n") -Encoding ASCII
}

Restart-Service sshd
Write-Host "Done. File at $filePath updated and permissions set."
```

E) Non-admin users (if you ever need it)

For regular users (not in the local Administrators group), use their profile:
```
# Run as the target user or with appropriate permissions to their profile
$userProfile = [Environment]::GetFolderPath('UserProfile')
$sshDir = Join-Path $userProfile '.ssh'
$auth  = Join-Path $sshDir 'authorized_keys'

if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir -Force | Out-Null }
if (-not (Test-Path $auth))   { New-Item -ItemType File      -Path $auth  -Force | Out-Null }

# Tighten ACLs: SYSTEM & the user only
$me = "$env:USERDOMAIN\$env:USERNAME"
icacls $sshDir /inheritance:r | Out-Null
icacls $sshDir /grant:r "$me:(F)" "SYSTEM:(F)" | Out-Null
icacls $auth  /inheritance:r | Out-Null
icacls $auth  /grant:r "$me:(F)" "SYSTEM:(F)" | Out-Null

# Append key if missing
$aduserpubkey = 'ssh-ed25519 AAAA...'
if (-not (Select-String -Path $auth -Pattern $aduserpubkey -SimpleMatch -Quiet)) {
    Add-Content -Path $auth -Value ($aduserpubkey + "`r`n") -Encoding ASCII
}
```

F) (Optional) Enforce public-key authentication only

By default, OpenSSH on Windows will still accept password logins for domain users. To lock down to pubkey only, edit C:\ProgramData\ssh\sshd_config and add/modify these lines (before any Match blocks):
```
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
GSSAPIAuthentication no
```
⚠️ GSSAPIAuthentication no disables Kerberos/SSO logins. If you want to allow domain single-sign-on, leave it as yes.

Idempotent PowerShell to apply the settings
```
$cfg = Join-Path $env:PROGRAMDATA 'ssh\sshd_config'

# Ensure file exists
if (-not (Test-Path $cfg)) { New-Item -Path $cfg -ItemType File -Force | Out-Null }

function Set-SshdConfigLine {
    param([string]$Key, [string]$Value)
    $pattern = "^\s*$([regex]::Escape($Key))\s+.*$"
    $line    = "$Key $Value"
    if (Select-String -Path $cfg -Pattern $pattern -Quiet) {
        (Get-Content $cfg) -replace $pattern, $line | Set-Content $cfg -Encoding ASCII
    } else {
        Add-Content -Path $cfg -Value ($line + "`r`n") -Encoding ASCII
    }
}

Set-SshdConfigLine 'PubkeyAuthentication' 'yes'
Set-SshdConfigLine 'PasswordAuthentication' 'no'
Set-SshdConfigLine 'KbdInteractiveAuthentication' 'no'
Set-SshdConfigLine 'GSSAPIAuthentication' 'no'

Restart-Service sshd
Write-Host "OpenSSH set to public-key only."
```

