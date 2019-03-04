<#PSScriptInfo
.VERSION 1.0.0
.GUID 1d426e51-df3b-4723-96ac-e7d790744f69
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
        Example script that disables the given Windows Event Log.
#>
Configuration WindowsEventlog_DisableWindowsEventlog_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsEventLog Enable-DscAnalytic
        {
            LogName             = 'Microsoft-Windows-Dsc/Analytic'
            IsEnabled           = $false
        } # End of Windows Event Log Resource
    } # End of Node
} # End of Configuration
