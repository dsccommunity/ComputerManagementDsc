<#PSScriptInfo
.VERSION 1.0.0
.GUID d39a7d09-4baa-44d2-bcb4-b37ae3f2e16b
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
        This example sets the current time zone on the node
        to 'Tonga Standard Time'.
#>
Configuration TimeZone_SetTimeZone_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        TimeZone TimeZoneExample
        {
            IsSingleInstance = 'Yes'
            TimeZone         = 'Tonga Standard Time'
        }
    }
}
