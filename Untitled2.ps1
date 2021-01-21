#Enable-PSRemoting –Force
#Install-Module -Name xActiveDirectory
#Install-Module -Name ActiveDirectoryDsc -Force
Configuration ADGroup_NewGroupWithMembers_Config
{
    Import-DscResource -ModuleName ActiveDirectoryDsc

    node localhost
    {
        ADGroup 'dl1'
        {
            GroupName  = 'DL_APP_1'
            GroupScope = 'DomainLocal'
            Members    = 'john', 'jim', 'sally'
        }
    }
}
