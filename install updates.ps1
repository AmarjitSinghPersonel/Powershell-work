[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name PSWindowsUpdate -Force
Add-WUServiceManager -MicrosoftUpdate  -Confirm:$false
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll  -AutoReboot