<#PSScriptInfo
.VERSION 1.0.0
.GUID 2d524871-2a87-43d2-be20-ba4cf0f529f4
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ComputerManagementDsc/blob/main/LICENSE
.PROJECTURI https://github.com/dsccommunity/ComputerManagementDsc
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
        This example creates a scheduled task called 'Test task Idle' in the folder
        task folder 'MyTasks' that starts a new powershell process when the computer
        is idle. The computer must be idle for 10 minutes and Task Scheduler waits
        1 hour for the idle condition to occur. Task Scheduler should stop the task if
        the computer ceases to be idle, and restarts the tasks if the idle state resumes.
#>
Configuration ScheduledTask_CreateScheduledTasksOnIdle_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask ScheduledTaskOnIdleAdd
        {
            TaskName = 'Test task Idle'
            TaskPath = '\MyTasks'
            Ensure = 'Present'
            ScheduleType = 'OnIdle'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            IdleDuration = '00:10:00'
            IdleWaitTimeout = '01:00:00'
            DontStopOnIdleEnd = $false
            RestartOnIdle = $true
        }
    }
}
