#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        This configuration installs the resource PackageManagement with version 1.4.7 on a machine
#>

configuration Install_PackageManagement_RequiredVersion_Present
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node localhost
    {
        PSResource 'Install_PackageManagement_RequiredVersion_Present'
        {
            Name            = 'PackageManagement'
            Ensure          = 'Present'
            Force           = $true
            RequiredVersion = '1.4.7'
        }
    }
}
