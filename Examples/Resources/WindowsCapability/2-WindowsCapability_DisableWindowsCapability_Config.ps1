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
        Example script that disables the Windows Capability XPS.Viewer~~~~0.0.1.0
#>
Configuration WindowsCapability_DisableWindowsCapability_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsCapability XPSViewer
        {
            Name   = 'XPS.Viewer~~~~0.0.1.0'
            Ensure = 'Absent'
            Online = $true
        } # End of Windows Capability Resource
    } # End of Node
} # End of Configuration
