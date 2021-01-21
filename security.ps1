$comp = "PsTestVm"
#Interactive logon screen Title message
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "legalnoticecaption" -Value "Welcome!"

#Interactive logon screen  Message Text
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "legalnoticetext" -Value "*** Authorized Access Only ***"

#Restricting user from changing the login account
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowYourAccount" -Name "value" -Value "0"

#Clear event log and value for module could be Application,secuiy,setup,system,forward events
clear-eventlog "windows powershell","system","application" -comp $comp

#Restriction for user to use digital signature 0=disable 1=enable
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "requiresecuritysignature" -Value "0"

#uninstall all 3rd party signature and filter results using name query
#(Get-WmiObject -Class Win32_Product  | Where-Object{$_.Name -notlike  "*Microsoft*"} | Where-Object{$_.Name -notlike  "*Dell*"} | Where-Object{$_.Name -notlike  "*Intel*"}).uninstall()

# we can also set value to 4 but both client and server should support that level of encryption
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "MinEncryptionLevel" -Value "2"

#NetBIOS enable disable over TCP/IP
# value 0 is for default setting 1 is for enable and 2 is for disable
$adapters=(Get-WmiObject -ComputerName $comp -Class Win32_NetworkAdapterConfiguration)
Foreach ($adapter in $adapters){
  Write-Host $adapter
  $adapter.settcpipnetbios(2)
}

# Turn ON OFF file and printer sharing options
Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled False -Profile Any

#Turn On Encryption
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Policies" -Name "NtfsDisableEncryption" -Value "1"
#Turn off Encryption
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Policies" -Name "NtfsDisableEncryption"

#Remoe all temporary files Use -Confirm:true is required permission
Remove-Item $env:TEMP\*.*  -force

