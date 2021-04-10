<#PSScriptInfo
.VERSION 1.0.0
.GUID 5e3f845c-58ce-4e46-baaf-2422d30176ca
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
        Example script that sets the MSPaint Admin event channel
        to log mode AutoBackup, a maximum size of 2048MB, log
        retention for 10 days, and ensure it is enabled.
#>
Configuration WindowsEventLog_SetLogMode_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsEventLog MSPaintAdmin
        {
            LogName            = 'Microsoft-Windows-MSPaint/Admin'
            IsEnabled          = $true
            LogMode            = 'AutoBackup'
            LogRetentionDays   = 10
            MaximumSizeInBytes = 2048KB
        }
    }
}
