$acl = Get-Acl 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers'
$idRef = [System.Security.Principal.NTAccount]("BUILTIN\Users")
$regRights = [System.Security.AccessControl.RegistryRights]::FullControl
$acType = [System.Security.AccessControl.AccessControlType]::Allow
$inhFlags = [System.Security.AccessControl.InheritanceFlags]::None
$prFlags = [System.Security.AccessControl.PropagationFlags]::None
$rule = New-Object System.Security.AccessControl.RegistryAccessRule ($idRef, $regRights,$inhFlags,$prFlags,$acType)
Write-Output($rule)
Write-Output($acl)
$acl.AddAccessRule($rule)
$acl | Set-Acl -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers'
(Get-Acl 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurePipeServers').Access