<#PSScriptInfo
.VERSION 1.0.0
.GUID 5e3f845c-58ce-4e46-baaf-2422d30176ca
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
        Example script that sets the application Windows Event Log
        to mode AutoBackup and logsize to a maximum size of 2048MB
        with a logfile retention for 10 days and ensure it is enabled.
#>
Configuration WindowsEventlog_SetWindowsEventlogLogMode_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsEventLog ApplicationEventlogMode
        {
            LogName            = 'Microsoft-Windows-MSPaint/Admin'
            IsEnabled          = $true
            LogMode            = 'AutoBackup'
            LogRetentionDays   = '10'
            MaximumSizeInBytes = 2048kb
        } # End of Windows Event Log Resource
    } # End of Node
} # End of Configuration
