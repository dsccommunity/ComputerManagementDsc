<#PSScriptInfo
.VERSION 1.0.0
.GUID 6900f247-5477-4821-9718-480f485db688
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
        This example shows how to configure multiple powershell's execution policy for a specified execution policy scope.
#>
Configuration PowerShellExecutionPolicy_SetPolicyForMultipleScopes_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        PowerShellExecutionPolicy ExecutionPolicyCurrentUser
        {
            ExecutionPolicyScope = 'CurrentUser'
            ExecutionPolicy      = 'RemoteSigned'
        } # End of ExecutionPolicyCurrentUser Resource

        PowerShellExecutionPolicy ExecutionPolicyLocalMachine
        {
            ExecutionPolicyScope = 'LocalMachine'
            ExecutionPolicy      = 'RemoteSigned'
        } # End of ExecutionPolicyLocalMachine Resource
    } # End of Node
} # End of Configuration
