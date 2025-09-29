if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}
$Username    = "username"
$FullName    = "displayname"
$Description = "login-description"
$Password    = "-omitted-"

# Convert plain text password to SecureString
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

Write-Host "Creating new local user: $Username, $Password"
# Create the local user
New-LocalUser -Name $Username `
              -FullName $FullName `
              -Description $Description `
              -Password $SecurePassword `
              -PasswordNeverExpires:$true `
              -UserMayNotChangePassword:$true

# (Optional) Add to "Users" group so the account can log in
Add-LocalGroupMember -Group "Users" -Member $Username

Write-Host "End of script, press enter to exit..."
Read-Host
