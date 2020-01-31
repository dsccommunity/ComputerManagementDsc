<#PSScriptInfo
.VERSION 1.0.0
.GUID 594bfeff-8e83-4cc4-8141-f3b39795c85b
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ComputerManagementDsc/blob/master/LICENSE
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
        This configuration will set the computer name to 'Server01'
        and make it part of 'ContosoWorkgroup' Workgroup.
#>
Configuration Computer_RenameComputerAndSetWorkgroup_Config
{
    Import-DscResource -Module ComputerManagementDsc

    Node localhost
    {
        Computer NewNameAndWorkgroup
        {
            Name          = 'Server01'
            WorkGroupName = 'ContosoWorkgroup'
        }
    }
}
