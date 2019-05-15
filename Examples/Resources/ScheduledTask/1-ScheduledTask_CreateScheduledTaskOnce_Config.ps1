<#PSScriptInfo
.VERSION 1.0.0
.GUID 4310a6c2-9f34-4ebc-8895-feda5286e532
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
        This example creates a scheduled task called 'Test task Once' in the folder
        task folder 'MyTasks' that starts a new powershell process once at 00:00 repeating
        every 15 minutes for 8 hours. The task is delayed by a random amount up to 1 hour
        each time. The task will run even if the previous task is still running and it
        will prevent hard termintaing of the previously running task instance. The task
        execution will have no time limit.
#>
Configuration ScheduledTask_CreateScheduledTaskOnce_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask ScheduledTaskOnceAdd
        {
            TaskName              = 'Test task Once'
            TaskPath              = '\MyTasks'
            ActionExecutable      = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType          = 'Once'
            RepeatInterval        = '00:15:00'
            RepetitionDuration    = '08:00:00'
            ExecutionTimeLimit    = '00:00:00'
            ActionWorkingPath     = (Get-Location).Path
            Enable                = $true
            RandomDelay           = '01:00:00'
            DisallowHardTerminate = $true
            RunOnlyIfIdle         = $false
            Priority              = 9
        }
    }
}
