<#PSScriptInfo
.VERSION 1.0.0
.GUID 6a49b259-754d-4825-b559-31029a10f5d7
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
        Enables system protection for the C drive and sets
        the maximum restore point disk usage to 5 percent.
#>
Configuration SystemProtection_EnableDriveC_5Percent_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        SystemProtection DriveC
        {
            Ensure      = 'Present'
            DriveLetter = 'C'
            DiskUsage   = 5
        }
    }
}
