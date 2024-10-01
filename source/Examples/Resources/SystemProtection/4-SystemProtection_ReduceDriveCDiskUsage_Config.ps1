<#PSScriptInfo
.VERSION 1.0.0
.GUID f0e26404-16fd-407c-832a-e69b30ec43b0
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
        Sets the maximum disk usage for Drive C to 15 percent.
        Assumes the current disk usage is configured for a
        higher percentage and you want to delete checkpoints.
#>
Configuration SystemProtection_ReduceDriveCDiskUsage_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SystemProtection DriveC
        {
            Ensure      = 'Present'
            DriveLetter = 'C'
            DiskUsage   = 15
            Force       = $true
        }
    }
}
