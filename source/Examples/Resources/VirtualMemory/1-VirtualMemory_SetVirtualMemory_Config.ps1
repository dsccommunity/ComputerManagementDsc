<#PSScriptInfo
.VERSION 1.0.0
.GUID 8ea6bdd3-8822-4e6e-9957-d8576a45c55a
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
        Example script that sets the paging file to reside on
        drive C with the custom size 2048MB.
#>
Configuration VirtualMemory_SetVirtualMemory_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        VirtualMemory PagingSettings
        {
            Type        = 'CustomSize'
            Drive       = 'C'
            InitialSize = '2048'
            MaximumSize = '2048'
        }
    }
}
