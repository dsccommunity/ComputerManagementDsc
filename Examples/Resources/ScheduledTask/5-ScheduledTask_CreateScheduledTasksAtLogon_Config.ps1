<#PSScriptInfo
.VERSION 1.0.0
.GUID 282cba27-4cf3-43b8-86f2-f6ef0f8b4489
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
        This example creates a scheduled task called 'Test task Logon' in the folder
        task folder 'MyTasks' that starts a new powershell process when the machine
        is logged on repeating every 15 minutes for 8 hours.
#>
Configuration ScheduledTask_CreateScheduledTasksAtLogon_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask ScheduledTaskLogonAdd
        {
            TaskName           = 'Test task Logon'
            TaskPath           = '\MyTasks'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtLogOn'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
        }
    }
}
