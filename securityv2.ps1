$comp = "PsTestVm"
$dirPath = "C:\ServerHardingLog"
$FileName = "Log" + (Get-Date).tostring("dd-MM-yyyy")
$Path = $dirPath+"\"+ $FileName+".txt"
$output = "Eventlog - " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")

if(!(Test-Path $dirPath))
{
    New-Item -ItemType Directory -Force -Path $dirPath
}


if (!(Test-Path $Path))
{
    New-Item -itemType File -Path $dirPath -Name ($FileName + ".txt")    
}

#############logging#############
$output = "Interactive logon screen title editing start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#Interactive logon screen Title message
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "legalnoticecaption" -Value "Welcome!"

#############logging#############
$output = "Interactive logon screen title editing End “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############
$output = "Interactive logon screen message editing start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#Interactive logon screen  Message Text
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "legalnoticetext" -Value "*** Authorized Access Only ***"

#############logging#############
$output = "Interactive logon screen message editing end “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############
$output = "User signin/out restriction - start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#Restricting user from changing the login account
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowYourAccount" -Name "value" -Value "0"

#############logging#############
$output = "User signin/out restriction - end “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############
$output = "Erasing event logs start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#Clear event log and value for module could be Application,secuiy,setup,system,forward events
clear-eventlog "windows powershell","system","application" -comp $comp

#############logging#############
$output = "Erasing event logs end “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Enable/Disable user digital signature start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#Restriction for user to use digital signature 0=disable 1=enable
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "requiresecuritysignature" -Value "0"

#############logging#############
$output = "Enable/Disable user digital signature start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Uninstall all 3rd party software start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#uninstall all 3rd party signature and filter results using name query
#(Get-WmiObject -Class Win32_Product  | Where-Object{$_.Name -notlike  "*Microsoft*"} | Where-Object{$_.Name -notlike  "*Dell*"} | Where-Object{$_.Name -notlike  "*Intel*"}).uninstall()

#############logging#############
$output = "Uninstall all 3rd party software end “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Raising level of encryption start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#Increasing the level of encryption
# we can also set value to 4 but both client and server should support that level of encryption
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "MinEncryptionLevel" -Value "2"

#############logging#############
$output = "Raising level of encryption end “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "NetBIOS over TCP/IP enable/disbale start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#NetBIOS enable disable over TCP/IP
# value 0 is for default setting 1 is for enable and 2 is for disable
$adapters=(Get-WmiObject -ComputerName $comp -Class Win32_NetworkAdapterConfiguration)
Foreach ($adapter in $adapters){
  Write-Host $adapter
  $adapter.settcpipnetbios(2)
}

#############logging#############
$output = "NetBIOS over TCP/IP enable/disbale start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Enable/Disbale Firewal start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

# Turn ON OFF file and printer sharing options
Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled False -Profile Any

#############logging#############
$output = "Enable/Disbale Firewal end “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Enable NTFS encryption starts" + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#Turn On NTFS Encryption
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Policies" -Name "NtfsDisableEncryption" -Value "1"

#############logging#############
$output = "Enable NTFS encryption starts" + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Disabling NTFS enryption start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#Turn off Encryption
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Policies" -Name "NtfsDisableEncryption"

#############logging#############
$output = "Disabling NTFS enryption end “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Removing temporary files start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#Remoe all temporary files Use -Confirm:true is required permission
Remove-Item $env:TEMP\*.*  -force

#############logging#############
$output = "Removing temporaray files end “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Activate screen saver start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#Activating screen saver
Reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 1 /f

#############logging#############
$output = "Activate screen saver end “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Setting screen saver timeout start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#Setting screen saver timeout
Reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v ScreenSaveTimeOut /t REG_SZ /d 300 /f

#############logging#############
$output = "Setting screen saver timeout end “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Securing screen saver start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############


#Applying secure screen saver
Reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d 1 /f 

#############logging#############
$output = "Securing screen saver end “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############
 

$output = "Deleting Internet explorer Cookies start “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

#Deleting Internet explorer cookies
Dir ([Environment]::GetFolderPath("Cookies")) | del -whatif -Recurse -Force -Confirm:$false
 
#############logging#############
$output = "Deleting Internet explorer Cookies end “ + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#############logging#############

