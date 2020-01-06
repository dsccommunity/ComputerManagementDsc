<#PSScriptInfo
.VERSION 1.0.0
.GUID 8bed07fe-c88f-4a22-bdd8-8ec95cf8739b
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
        This example deletes the built-in scheduled task called
        'CreateExplorerShellUnelevatedTask'.
#>
Configuration ScheduledTask_DeleteABuiltInTask_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask DeleteCreateExplorerShellUnelevatedTask
        {
            TaskName            = 'CreateExplorerShellUnelevatedTask'
            TaskPath            = '\'
            Ensure              = 'Absent'
        }
    }
}
