# v1.2 Kevin Yu (20/11/25)
# This script will configure the IP address and DNS address of the computer.

# Gain administrator permissions
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Maximized; exit 
}

# Set DNS address to static address OR NOT
$enableStaticDNS = $true  # set this to $true if you want to enable static DNS
$staticDNSIPv4 = "10.5.10.20", "8.8.8.8"
$defaultGateway = "10.5.40.1"
# **CHANGE ABOVE ADDRESSES IF USING STATIC ADDRESSES**

# Set IP address header
$newIPheader = "10.5.40."
# This value will be added to the start of whatever value you enter for the IP address.
# Useful when setting multiple IP address in succession, no need to keep typing the same 10.5.40.
# Leave blank if you want to manually set everytime.

Write-Host "Initialising..."
# Current network configuration information
# check if there is more than one ethernet connection
$availableNetworks = Get-NetIPConfiguration -detailed | Where-Object {$_.InterfaceAlias -like '*ethernet*'}
$numberOfNetworks = $availableNetworks.Count
if ($numberOfNetworks -ge 2) {
	# If there's more than one, show status information and let the user choose
	Write-Host "More than 1 ethernet connection was identified, please select which one to use:" -ForegroundColor Yellow
	foreach ($network in $availableNetworks) {
		$index = $network.InterfaceIndex
		$alias = $network.InterfaceAlias
		$status = $network.NetAdapter.Status
		$netProfileName = $network.NetProfile.Name
		Write-Host "Index: $index, Alias: $alias, Name: $netProfileName, Status: $status"
	}
	Write-Host "Please select the network index: " -ForegroundColor Yellow
	$chosenNetworkIndex = Read-Host
	while (-not $chosenNetworkIndex) {
		Write-Host "Invalid input, try again:" -ForegroundColor Red
		$chosenNetworkIndex = Read-Host
	}
	$chosenNetworkAlias = (Get-NetIPConfiguration -InterfaceIndex $chosenNetworkIndex).interfacealias
}

if ($chosenNetworkIndex) {
	$currentIP = (Get-NetIPConfiguration -InterfaceIndex $chosenNetworkIndex).IPv4Address.IPAddress
	Get-NetIPAddress -InterfaceIndex $chosenNetworkIndex |  Remove-NetRoute -Confirm:$false
	Get-NetIPAddress -InterfaceIndex $chosenNetworkIndex |  Remove-NetIPAddress -Confirm:$false
	$currentDHCPStatusIPv4 = (Get-NetIPConfiguration -InterfaceIndex $chosenNetworkIndex).NetIPv4Interface.dhcp
} else {
	$currentIP = (Get-NetIPConfiguration -InterfaceAlias Ethernet).IPv4Address.IPAddress
	Get-NetIPAddress -InterfaceAlias Ethernet |  Remove-NetRoute -Confirm:$false
	Get-NetIPAddress -InterfaceAlias Ethernet |  Remove-NetIPAddress -Confirm:$false
	$currentDHCPStatusIPv4 = (Get-NetIPConfiguration -InterfaceAlias Ethernet).NetIPv4Interface.dhcp
}

# Display current network configuration
Write-Host "=== Current configuration information ==="
Write-Host "Current IP Address = '$currentIP'"
Write-Host "Current DHCP Status = IPv4: '$currentDHCPStatusIPv4'"
Write-Host "=== Current configuration information ===`n`n"

# Display new (to be set) network configuration
Write-Host "=== New configuration information ==="
if ($enableStaticDNS) {
    Write-Host "With static DNS: '$staticDNSIPv4' to be enabled"
} else {
    Write-Host "DNS Address(s) DHCP: To be enabled"
}
Write-Host "=== New configuration information ===`n`n"

# Apply changes
Write-Host "===Applying new changes...===`n"
if ($chosenNetworkIndex) {
	Write-Host "Enabling DHCP for IPv4 and removing old address..."
	Write-Host "Enter the new IP address: $newIPheader"
	$newIP = Read-Host
	New-NetIPAddress -IPAddress "$newIPheader$newIP" -PrefixLength 24 -InterfaceIndex $chosenNetworkIndex -DefaultGateway $defaultGateway
	if ($enableStaticDNS) {
		Write-Host "Setting DNS addresses to static: '$staticDNSIPv4'" -ForegroundColor Green
		Set-DNSClientServerAddress -InterfaceIndex $chosenNetworkIndex -ServerAddresses ($staticDNSIPv4)
	} else {
		Write-Host "Setting DNS addresses to automatic (DHCP)..."
		Set-DNSClientServerAddress -InterfaceIndex $chosenNetworkIndex -ResetServerAddresses
	}
} else {
	Write-Host "Enabling DHCP for IPv4 and removing old address..."
	Write-Host "Enter the new IP address: $newIPheader"
	$newIP = Read-Host
	New-NetIPAddress -IPAddress "$newIPheader$newIP" -PrefixLength 24 -InterfaceAlias Ethernet -DefaultGateway $defaultGateway
	if ($enableStaticDNS) {
		Write-Host "Setting DNS addresses to static: '$staticDNSIPv4'" -ForegroundColor Green
		Set-DNSClientServerAddress -InterfaceAlias Ethernet -ServerAddresses ($staticDNSIPv4)
	} else {
		Write-Host "Setting DNS addresses to automatic (DHCP)..."
		Set-DNSClientServerAddress -InterfaceAlias Ethernet -ResetServerAddresses
	}
}

Write-Host "`nPress Enter to Exit..."
Read-Host
