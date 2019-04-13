<#PSScriptInfo
.VERSION 1.0.0
.GUID f05286e4-e357-40f8-ba62-e49d4d50eb0f
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
        Example script that sets the Dsc Analytic Windows Event Log
        to size maximum size 4096MB, with logmode 'Retain' and ensure it is enabled.
#>
Configuration WindowsEventlog_EnableWindowsEventLog_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsEventLog Enable-DscAnalytic
        {
            LogName             = 'Microsoft-Windows-Dsc/Analytic'
            IsEnabled           = $True
            LogMode             = 'Retain'
            MaximumSizeInBytes  = 4096kb
            LogFilePath         = "%SystemRoot%\System32\Winevt\Logs\Microsoft-Windows-DSC%4Analytic.evtx"
        } # End of Windows Event Log Resource
    } # End of Node
} # End of Configuration
