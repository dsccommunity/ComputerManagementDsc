<#PSScriptInfo
.VERSION 1.0.0
.GUID adade795-9143-4f4a-ae2d-4e31e81029a2
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
        Example script that adds the Windows Capability XPS.Viewer~~~~0.0.1.0
#>
Configuration WindowsCapability_AddWindowsCapability_Config
{
    Import-DSCResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        WindowsCapability XPSViewer
        {
            Name   = 'XPS.Viewer~~~~0.0.1.0'
            Ensure = 'Present'
        }
    }
}
