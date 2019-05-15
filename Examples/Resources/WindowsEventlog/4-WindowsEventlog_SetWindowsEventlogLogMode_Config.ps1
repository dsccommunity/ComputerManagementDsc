<#PSScriptInfo
.VERSION 1.0.0
.GUID 1e24ee07-cb2f-489b-af15-ebf6ffa864fe
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
        logmode to 'Autobackup' with 30 days retention and ensure it is enabled.
#>
Configuration WindowsEventlog_SetWindowsEventlogLogMode_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsEventLog ApplicationEventlogSize
        {
            LogName            = 'Application'
            IsEnabled          = $true
            LogMode            = 'AutoBackup'
            LogRetentionDays   = 30
        } # End of Windows Event Log Resource
    } # End of Node
} # End of Configuration
