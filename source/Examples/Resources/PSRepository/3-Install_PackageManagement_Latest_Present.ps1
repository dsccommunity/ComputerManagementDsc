#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        This configuration installs the latest version of the resource PowerShellGet on a machine
#>

configuration Install_PackageManagement_RequiredVersion_Present
{
    Import-DscResource -ModuleName 'ComputerManagementDsc'

    node localhost
    {
        PSResource 'Install_PackageManagement_RequiredVersion_Present'
        {
            Name   = 'PowerShellGet'
            Ensure = 'Present'
            Force  = $true
            Latest = $true
        }
    }
}
