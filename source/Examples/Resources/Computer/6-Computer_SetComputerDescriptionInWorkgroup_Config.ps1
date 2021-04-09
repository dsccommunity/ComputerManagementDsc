<#PSScriptInfo
.VERSION 1.0.0
.GUID 315d9349-c340-4c6d-970e-8e5d2bb5b12b
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
        This example will set the computer description.
#>
Configuration Computer_SetComputerDescriptionInWorkgroup_Config
{
    Import-DscResource -Module ComputerManagementDsc

    Node localhost
    {
        Computer NewDescription
        {
            Name        = 'localhost'
            Description = 'This is my computer.'
        }
    }
}
