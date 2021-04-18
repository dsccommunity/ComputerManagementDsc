<#PSScriptInfo
.VERSION 1.0.0
.GUID d1d1183a-331d-415c-b2d5-cbf15ef462f5
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
        Configures automtic restore point frequency to 12 hours.
        Frequency is a system-wide setting and must be declared
        in its own resource declaration (not with a drive letter).
#>
Configuration SystemProtection_AutoRestorePoint12Hours_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SystemProtection AutoRestorePointFrequency
        {
            Ensure    = 'Present'
            Frequency = 720
        }
    }
}
