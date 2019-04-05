<#PSScriptInfo
.VERSION 1.0.0
.GUID ae57d854-a9ae-4b3b-808d-3f23423beb29
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
        This example creates a scheduled task called 'Test task Daily Indefinitely' in the folder
        task folder 'MyTasks' that starts a new powershell process every day at 00:00 repeating
        every 15 minutes indefinitely.
#>
Configuration ScheduledTask_CreateScheduledTasksDailyIndefinitely_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask ScheduledTaskDailyIndefinitelyAdd
        {
            TaskName           = 'Test task Daily Indefinitely'
            TaskPath           = '\MyTasks'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Daily'
            DaysInterval       = 1
            RepeatInterval     = '00:15:00'
            RepetitionDuration = 'Indefinitely'
        }
    }
}
