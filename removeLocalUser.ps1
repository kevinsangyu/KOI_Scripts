if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

# The User to remove
$Username = "username"

Write-Host "Removing local user: $Username"
Remove-LocalUser -Name $Username

Write-Host "Script completed, press enter to exit..."
Read-Host