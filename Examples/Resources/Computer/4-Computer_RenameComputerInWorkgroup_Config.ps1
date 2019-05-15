<#PSScriptInfo
.VERSION 1.0.0
.GUID 7a5bc1c3-5229-48ec-9145-816d02e4544d
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT (c) Microsoft Corporation. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/ComputerManagementDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/ComputerManagementDsc
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
        This example will set the machine name to 'Server01' while remaining
        in the workgroup.
#>
Configuration Computer_RenameComputerInWorkgroup_Config
{
    Import-DscResource -Module ComputerManagementDsc

    Node localhost
    {
        Computer NewName
        {
            Name = 'Server01'
        }
    }
}
