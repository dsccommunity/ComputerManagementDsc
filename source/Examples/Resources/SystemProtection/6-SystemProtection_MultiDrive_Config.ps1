<#PSScriptInfo
.VERSION 1.0.0
.GUID ef7f184e-1b0f-4eba-91a8-2aafe209b25c
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
        Sets the maximum disk usage for Drive C 15 percent.
        Assumes the current disk usage is configured for a
        higher percentage.
#>
Configuration SystemProtection_MultiDrive_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SystemProtection DriveC
        {
            Ensure      = 'Present'
            DriveLetter = 'C'
            DiskUsage   = 15
        }

        SystemProtection DriveD
        {
            Ensure      = 'Present'
            DriveLetter = 'D'
            DiskUsage   = 25
        }
    }
}
