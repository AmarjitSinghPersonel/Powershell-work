$User = 'AzureUser'
$PWord = ConvertTo-SecureString -String "Password@1234" -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $PWord
$MemberToInclude = 'AzureUser','Guest'
Configuration AddGroupMembers {
 
    param (
        [Parameter(Mandatory)]
        [System.String]
        $GroupName,
 
        [Parameter(Mandatory)]
        [System.String[]]
        $MembersToInclude,
 
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        $Credential
    
    )
 
    Import-DscResource -ModuleName PSDesiredStateConfiguration -Name Group
 
    Node $AllNodes.NodeName { 
        Group AddGroupMembers {
            Ensure = 'Present'
            GroupName = $GroupName
            MembersToInclude = $MembersToInclude
            Credential = $Credential
        }
    }
}
 
$ConfigData = @{
    AllNodes = @(
        @{
            # the name of the target node
            NodeName = 'localhost'
 
            # This is not recommended, only for testing purposes. Replace with Thumbprint and CertificateFile after testing.
            PsDscAllowPlainTextPassword = $true
 
            # Suppress warning: It is not recommended to use domain credential ...
            PSDscAllowDomainUser = $true
        }
    )
}

$AddParams = @{
    GroupName = 'DL_APP_4'
    MembersToInclude = $MemberToInclude
    Credential = $Cred
   # Credential = (Get-Credential -Credential 'AzureUser' )
    ConfigurationData = $ConfigData
}
AddGroupMembers @AddParams -OutputPath:"C:\EnvironmentVariable_Path"
Start-DscConfiguration -Path 'C:\EnvironmentVariable_Path' -Wait -Verbose -Force
