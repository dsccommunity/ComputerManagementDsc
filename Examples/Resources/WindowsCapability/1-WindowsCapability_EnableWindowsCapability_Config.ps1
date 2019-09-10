<#PSScriptInfo
.VERSION 1.0.0
.GUID f8fb71fd-9f4a-4ae5-93b8-53362752e37d
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
        Example script that enables the Windows Capability Browser.InternetExplorer
#>
Configuration WindowsEventlog_SetWindowsEventlogSize_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsCapability BrowserInternetExplorer
        {
            Name            = 'Application'
            Ensure          = 'Present'

        } # End of Windows Capability Resource
    } # End of Node
} # End of Configuration
