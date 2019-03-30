<#PSScriptInfo
.VERSION 1.0.0
.GUID d878a4e7-da0b-4099-b8e3-3442717b4c97
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
        This example shows how to configure powershell's execution policy for the specified execution policy scope.
#>
Configuration PowerShellExecutionPolicy_SetPolicy_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        PowerShellExecutionPolicy ExecutionPolicy
        {
            ExecutionPolicyScope = 'CurrentUser'
            ExecutionPolicy      = 'RemoteSigned'
        } # End of PowershellExecutionPolicy Resource
    } # End of Node
} # End of Configuration
