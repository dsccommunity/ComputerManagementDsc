<#PSScriptInfo
.VERSION 1.0.0
.GUID d0847694-6a83-4f5b-bf6f-30cb078033bc
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ComputerManagementDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/ComputerManagementDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        This example creates an SMB share named 'Temp' for the path 'C:\Temp',
        using the default values of the cmdlet `New-SmbShare`.

    .NOTES
        To know the default values, see the documentation for the cmdlet
        `New-SmbShare`.
#>
Configuration SmbShare_CreateShare_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SmbShare 'TempShare'
        {
            Name = 'Temp'
            Path = 'C:\Temp'
        }
    }
}
