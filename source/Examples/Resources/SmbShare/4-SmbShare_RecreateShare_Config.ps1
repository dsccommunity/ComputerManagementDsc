<#PSScriptInfo
.VERSION 1.0.0
.GUID ea641782-74b4-4673-94fe-336cbd196c16
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
        This example creates an SMB share named 'Share' for the path 'C:\Share1',
        using the default values of the cmdlet `New-SmbShare`. If the share
        already exists, it will drop the share and recreate it on the new path
        because Force is set to true.

    .NOTES
        To know the default values, see the documentation for the cmdlet
        `New-SmbShare`.
#>
Configuration SmbShare_RecreateShare_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SmbShare 'RecreateShare'
        {
            Name = 'Share'
            Path = 'C:\Share1'
            Force = $true
        }
    }
}
