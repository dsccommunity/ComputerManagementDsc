<#PSScriptInfo
.VERSION 1.0.0
.GUID c3422e70-79ea-4afa-9558-1fcbe18dd0bd
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
        This example disables the built-in scheduled task called
        'CreateExplorerShellUnelevatedTask'.
#>
Configuration ScheduledTask_DisableABuiltInTask_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask DisableCreateExplorerShellUnelevatedTask
        {
            TaskName            = 'CreateExplorerShellUnelevatedTask'
            TaskPath            = '\'
            Enable              = $false
        }
    }
}
