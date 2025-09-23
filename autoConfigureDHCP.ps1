# v1.0 Kevin Yu (23/09/25)
# This script changes the network settings for the Ethernet connection:
# Enables DHCP for IP address and automatically get the DNS addresses from the server

# Gain administrator permissions
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit 
}

# Set DNS address to static address OR NOT
$enableStaticDNS = $false  # set this to $true if you want to enable static DNS
$staticDNSIPv4 = "8.8.8.8", "10.3.10.25"  
# **CHANGE ABOVE ADDRESSES IF USING STATIC ADDRESSES**

# Current network configuration information
$currentIP = (Get-NetIPConfiguration -InterfaceAlias Ethernet).IPv4Address.IPAddress
$currentDHCPStatusIPv4 = (Get-NetIPConfiguration -InterfaceAlias Ethernet).NetIPv4Interface.dhcp

# Display current network configuration
Write-Host "=== Current configuration information ==="
Write-Host "Current IP Address = '$currentIP'"
Write-Host "Current DHCP Status = IPv4: '$currentDHCPStatusIPv4'"
Write-Host "=== Current configuration information ===`n`n"

# Display new (to be set) network configuration
Write-Host "=== New configuration information ==="
Write-Host "IP Address DHCP: To be enabled"
if ($enableStaticDNS) {
	Write-Host "With static DNS: '$staticDNSIPv4' to be enabled"
} else {
	Write-Host "DNS Address(s) DHCP: To be enabled"
}
Write-Host "=== New configuration information ===`n`n"

# Apply changes
Write-Host "===Applying new changes...===`n"
Write-Host "Enabling DHCP for IPv4 and removing old address..."
Set-NetIPInterface -InterfaceAlias Ethernet -Dhcp Enabled -AddressFamily IPv4 | Remove-NetIPAddress -InterfaceAlias Ethernet
if ($enableStaticDNS) {
	Write-Host "Setting DNS addresses to static: '$staticDNSIPv4'"
	Set-DNSClientServerAddress -InterfaceAlias Ethernet -ServerAddresses ($staticDNSIPv4)
} else {
	Write-Host "Setting DNS addresses to automatic (DHCP)..."
	Set-DNSClientServerAddress -InterfaceAlias Ethernet -ResetServerAddresses
}
Write-Host "Renewing address from DHCP..."
Start-Process -FilePath "ipconfig.exe" -ArgumentList "/renew Ethernet" -noNewWindow -Wait
# Above step is necessary to assure that a new ip address is fetched from the server, as otherwise it just replaces the previous one

Write-Host "`nChanges applied, Press Enter to Exit..."
Read-Host
