
#Directory Path for logging
$dirPath = "C:\ServerHardingLog"

#Log file name with time stamp
$FileName = "Log" + (Get-Date).tostring("dd-MM-yyyy")

#Full directory and file path
$Path = $dirPath+"\"+ $FileName+".txt"

#If Directory path does not exist. Create here
if(!(Test-Path $dirPath))
{
    New-Item -ItemType Directory -Force -Path $dirPath
}

#If file does not exist.Create here
if (!(Test-Path $Path))
{
    New-Item -itemType File -Path $dirPath -Name ($FileName + ".txt")    
}

$output = "Activate screen saver start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

#Activating screen saver
Reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 1 /f
Reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 1 /f

$output = "Activate screen saver end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$outPt = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" 
$output = "ScreenSaveActive - "+ $outPt.ScreenSaveActive
Add-Content -Path $Path -Value $output
$output = "Setting screen saver timeout start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 
#Setting screen saver timeout
Reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop" /v ScreenSaveTimeOut /t REG_SZ /d 60 /f
Reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v ScreenSaveTimeOut /t REG_SZ /d 60 /f

$output = "Setting screen saver timeout end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$outPt = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" 
$output = "ScreenSaveTimeOut - "+ $outPt.ScreenSaveTimeOut
Add-Content -Path $Path -Value $output

$output = "Securing screen saver start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 
#Applying secure screen saver



Reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d 1 /f


$output = "Securing screen saver end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$outPt = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" 
$output = "ScreenSaverIsSecure - "+ $outPt.ScreenSaverIsSecure
Add-Content -Path $Path -Value $output

$output = "HKLM-ScreenSaverIsSecure Start "
Add-Content -Path $Path -Value $output
Reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d 1 /f
$output = "HKLM-ScreenSaverIsSecure End "
Add-Content -Path $Path -Value $output


$output = "ScreenSaver Mystify Start"
Add-Content -Path $Path -Value $output
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v SCRNSAVE.EXE /t REG_SZ /d C:\Windows\System32\Mystify.scr /f
$output = "ScreenSaver Mystify Start"
Add-Content -Path $Path -Value $output

$output = "HKLM - ScreenSaver Mystify Start"
Add-Content -Path $Path -Value $output

reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop" /v SCRNSAVE.EXE /t REG_SZ /d C:\Windows\System32\Mystify.scr /f

$output = "HKLM - ScreenSaver Mystify End"
Add-Content -Path $Path -Value $output
#User Account Policies
# Found these accounts under 2019 DataCenter

$output = "Get-LocalUser Guest Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

Get-LocalUser Guest | Disable-LocalUser

$output = "Get-LocalUser Guest End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$output = "Get-LocalUser DefaultAccount Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

Get-LocalUser DefaultAccount | Disable-LocalUser

$output = "Get-LocalUser DefaultAccount End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$output = "Get-LocalUser WDAGUtilityAccount Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

Get-LocalUser WDAGUtilityAccount | Disable-LocalUser

$output = "Get-LocalUser WDAGUtilityAccount End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$output = "Setting password Lenght Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

# setting password Lenght
net accounts /MINPWLEN:14

$output = "Setting password Lenght End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$output = "Setting password Complexity Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

# Setting password complexity enabled
secedit /export /cfg c:\secpol.cfg
(gc C:\secpol.cfg).replace("PasswordComplexity = 0", "PasswordComplexity = 1") | Out-File C:\secpol.cfg
secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
rm -force c:\secpol.cfg -confirm:$false

$output = "Setting password Complexity End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$output = "Setting Account Lockout Attempts Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

# Account Lockout Attempts
net accounts /lockoutthreshold:3

$output = "Setting Account Lockout Attempts End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 
$output = "Limit system eventLog size Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
#Log Size
limit-eventLog -logname "system" -MaximumSize 3999MB

$output = "Limit eventLog size End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$output = "Limit Security eventLog size Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

limit-eventLog -logname "Security" -MaximumSize 3999MB

$output = "Limit Security eventLog size End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$output = "Limit Application eventLog size Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

limit-eventLog -logname "Application" -MaximumSize 3999MB

$output = "Limit Application eventLog size End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$output = "Limit system eventLog RetentionDays Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

# Get-EventLog -List to see retention days
Limit-EventLog -OverflowAction OverwriteOlder -LogName "system" -RetentionDays 60

$output = "Limit system eventLog RetentionDays End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$output = "Limit Application eventLog RetentionDays Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

Limit-EventLog -OverflowAction OverwriteOlder -LogName "Application" -RetentionDays 60

$output = "Limit Application eventLog RetentionDays End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$output = "Limit Security eventLog RetentionDays End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

Limit-EventLog -OverflowAction OverwriteOlder -LogName "Security" -RetentionDays 60

$output = "Limit Security eventLog RetentionDays End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output


 
$output = "Interactive logon screen title editing start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

#Interactive logon screen Title message
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "legalnoticecaption" -Value "Welcome!"

 
$output = "Interactive logon screen title editing End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$outPt = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" 
$output = "legalnoticecaption - "+ $outPt.legalnoticecaption
Add-Content -Path $Path -Value $output
 
$output = "Interactive logon screen message editing start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

#Interactive logon screen  Message Text
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "legalnoticetext" -Value "*** Authorized Access Only ***"

 
$output = "Interactive logon screen message editing end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$outPt = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" 
$output = "legalnoticetext - "+ $outPt.legalnoticetext
Add-Content -Path $Path -Value $output
 
$output = "User signin/out restriction - start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

#Restricting user from changing the login account
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowYourAccount" -Name "value" -Value "0"

 
$output = "User signin/out restriction - end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$outPt = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowYourAccount" 
$output = "AllowYourAccount - "+ $outPt.value
Add-Content -Path $Path -Value $output
 
$output = "Erasing event logs start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

#Clear event log and value for module could be Application,secuiy,setup,system,forward events
clear-eventlog "windows powershell","system","application" 

 
$output = "Erasing event logs end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Enable/Disable user digital signature start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

#Restriction for user to use digital signature 0=disable 1=enable
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "requiresecuritysignature" -Value "0"

 
$output = "Enable/Disable user digital signature start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" 
$output = "requiresecuritysignature - "+ $outPt.requiresecuritysignature
Add-Content -Path $Path -Value $output
$output = "Uninstall all 3rd party software start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

#uninstall all 3rd party signature and filter results using name query
$app = Get-WmiObject -Class Win32_Product  | Where-Object{$_.Name -notlike  "*Microsoft*"} | Where-Object{$_.Name -notlike  "*Dell*"} | Where-Object{$_.Name -notlike  "*Intel*"} 
    
    if(-not ([string]::IsNullOrEmpty($app))) 
    {
        $app.uninstall()
    }

 
$output = "Uninstall all 3rd party software end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Raising level of encryption start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

#Increasing the level of encryption
# we can also set value to 4 but both client and server should support that level of encryption
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "MinEncryptionLevel" -Value "2"

 
$output = "Raising level of encryption end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" 
$output = "MinEncryptionLevel - "+ $outPt.MinEncryptionLevel
Add-Content -Path $Path -Value $output
$output = "NetBIOS over TCP/IP enable/disbale start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

#NetBIOS enable disable over TCP/IP
# value 0 is for default setting 1 is for enable and 2 is for disable
$key = "HKLM:SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces"
Get-ChildItem $key |
foreach { Set-ItemProperty -Path "$key\$($_.pschildname)" -Name NetbiosOptions -Value 2 }

Get-ChildItem $key |
foreach { $outPt = Get-ItemProperty -Path "$key\$($_.pschildname)"
$output = $($_.pschildname) +" - "+ $outPt.NetbiosOptions
Add-Content -Path $Path -Value $output }


 
$output = "NetBIOS over TCP/IP enable/disbale start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Enable/Disbale Firewal file and printer start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

# Turn ON OFF file and printer sharing options
Set-NetFirewallRule -DisplayGroup "File And Printer Sharing" -Enabled False -Profile Any

 
$output = "Enable/Disbale Firewal end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output



$output = "Enable/Disbale Firewal start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

# Turn ON OFF file and printer sharing options
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

 
$output = "Enable/Disbale Firewal end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Enable NTFS encryption starts" + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")


Add-Content -Path $Path -Value $output
 

#Turn On NTFS Encryption
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Policies" -Name "NtfsDisableEncryption" -Value "1"

$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Policies" 
$output = "NtfsDisableEncryption - "+ $outPt.NtfsDisableEncryption
Add-Content -Path $Path -Value $output
 
$output = "Enable NTFS encryption starts" + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Disabling NTFS enryption start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

#Turn off Encryption
Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Policies" -Name "NtfsDisableEncryption"

 
$output = "Disabling NTFS enryption end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
$output = "Removing temporary files start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

#Remoe all temporary files Use -Confirm:true is required permission
Remove-Item $env:TEMP\*.*  -force

 
$output = "Removing temporaray files end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

$output = "Deleting Internet explorer Cookies start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output
 

#Deleting Internet explorer cookies
Dir ([Environment]::GetFolderPath("Cookies")) | del -whatif -Recurse -Force -Confirm:$false
 
 
$output = "Deleting Internet explorer Cookies end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output


 
$output = "Disallow Remote registry access start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$acl = Get-Acl 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg'
$idRef = [System.Security.Principal.NTAccount]("BUILTIN\Users")
$regRights = [System.Security.AccessControl.RegistryRights]::FullControl
$acType = [System.Security.AccessControl.AccessControlType]::Allow
$inhFlags = [System.Security.AccessControl.InheritanceFlags]::None
$prFlags = [System.Security.AccessControl.PropagationFlags]::None
$rule = New-Object System.Security.AccessControl.RegistryAccessRule ($idRef, $regRights,$inhFlags,$prFlags,$acType)
Write-Output($rule)
Write-Output($acl)
$acl.AddAccessRule($rule)
$acl | Set-Acl -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg'

$outPt = (Get-Acl 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers\winreg').Access
$output = "Access to the remote registry - "+ $outPt.AccessControlType
Add-Content -Path $Path -Value $output

$output = "Disallow Remote registry access end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output


#Download User Right File from Blob storage
$requestHeader = @{  
  "Content-Type" = "application/octet-stream"
}
$BaseURI="https://aibstagstor1594635273.blob.core.windows.net/psfile/UserRights3.psm1"
#$BaseURI="https://aibstagstor1594635273.blob.core.windows.net/psfiles/UserRights (1).psm1"
Invoke-RestMethod -Headers $requestheader -Uri $BaseURI  -Method Get -OutFile UserRights3.psm1

$output = "Dowload UserRights.psm1 File End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

# User Rights Assignment
# Restrict the ability to access this computer from the network to Administrators and Authenticated Users.

$output = "Import UserRights.psm1 Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

Import-Module .\UserRights3.psm1 -Verbose
# Import-Module -Name c:\buildArtifacts\windows-image\UserRights.psm1 -Verbose

$output = "Import UserRights.psm1 End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$output = "Revoke User Rights(Guest) Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

Grant-UserRight -Account "Guest" -Right SeDenyNetworkLogonRight
Revoke-UserRight -Account "S-1-1-0" -Right SeNetworkLogonRight # It will Revoke Eveyone
Revoke-UserRight -Account "Guest" -Right SeNetworkLogonRight

Grant-UserRight -Account "Guest" -Right SeDenyServiceLogonRight
Revoke-UserRight -Account "Guest" -Right SeServiceLogonRight

Grant-UserRight -Account "Guest" -Right SeDenyBatchLogonRight
Revoke-UserRight -Account "Guest" -Right SeBatchLogonRight

Grant-UserRight -Account "Guest" -Right SeDenyRemoteInteractiveLogonRight
Revoke-UserRight -Account "Guest" -Right SeRemoteInteractiveLogonRight

Grant-UserRight -Account "Guest" -Right SeDenyInteractiveLogonRight
Revoke-UserRight -Account "Guest" -Right SeInteractiveLogonRight

$output = "Revoke User Rights(Guest) End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output


$output = "Disabling CD rom start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\cdrom" -Name "Start" -Value 4

$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\cdrom" 
$output = "cdrom - "+ $outPt.start
Add-Content -Path $Path -Value $output

$output = "Disabling CD rom End " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

$output = "Disabling Floppy drive start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\flpydisk" -Name "Start" -Value 4

$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\flpydisk" 
$output = "Floppy drive - "+ $outPt.start
Add-Content -Path $Path -Value $output

$output = "Disabling Floppy drive end " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

# $output = "System Restart Start " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
# Add-Content -Path $Path -Value $output
# Restart-Computer 


$output = "SSL 2.0 Client " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

Reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" /v DisabledByDefault /t REG_DWORD /d 1 /f

$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Client" 
$output = "SSL 2.0 Client - "+ $outPt.start
Add-Content -Path $Path -Value $output

$output = "SSL 2.0 Server " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

Reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" /v Enabled /t REG_DWORD /d 0 /f

$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0\Server" 
$output = "SSL 2.0 Server - "+ $outPt.start
Add-Content -Path $Path -Value $output

$output = "SSL 3.0 Client " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output

Reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" /v EnDisabledByDefaultabled /t REG_DWORD /d 1 /f

$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client" 
$output = "SSL 3.0 Client - "+ $outPt.start
Add-Content -Path $Path -Value $output

$output = "SSL 3.0 Server " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output


Reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" /v Enabled /t REG_DWORD /d 0 /f

$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Server" 
$output = "SSL 3.0 server - "+ $outPt.start
Add-Content -Path $Path -Value $output

$output = "TSL 1.1 Server " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output


Reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" /v Enabled /t REG_DWORD /d 0 /f

$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Server" 
$output = "TSL 1.1 Server - "+ $outPt.start
Add-Content -Path $Path -Value $output

$output = "TLS 1.2 Client " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output


Reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v DisabledByDefault /t REG_DWORD /d 0 /f

$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" 
$output = "TLS 1.2 Client - "+ $outPt.start
Add-Content -Path $Path -Value $output

$output = "TLS 1.2 Client Enabled " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output


Reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" /v Enabled /t REG_DWORD /d 1 /f

$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" 
$output = "TLS 1.2 Client Enabled- "+ $outPt.start
Add-Content -Path $Path -Value $output

$output = "TLS 1.2  Server " + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output


Reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v DisabledByDefault /t REG_DWORD /d 0 /f

$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" 
$output = "TLS 1.2 Server- "+ $outPt.start
Add-Content -Path $Path -Value $output

$output = "TLS 1.2  Server Enabled" + (Get-Date).tostring("dd-MM-yyyy hh:mm ss")
Add-Content -Path $Path -Value $output


Reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" /v Enabled /t REG_DWORD /d 1 /f

$outPt = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" 
$output = "TLS 1.2 Server Enabled - "+ $outPt.start
Add-Content -Path $Path -Value $output




Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PSWindowsUpdate -Force

Add-WUServiceManager -MicrosoftUpdate  -Confirm:$false

Start-Sleep -s 180

Install-WindowsUpdate -MicrosoftUpdate -AcceptAll  -AutoReboot