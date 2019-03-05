<#PSScriptInfo
.VERSION 1.0.0
.GUID 8817eedf-02f5-4477-8b2d-55fa73f33902
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
        This example creates a scheduled task called 'Test task Weekly' in the folder
        task folder 'MyTasks' that starts a new powershell process every week on
        Monday, Wednesday and Saturday at 00:00 repeating every 15 minutes for 8 hours.
        The task will be hidden and will be allowed to start if the machine is running
        on batteries. The task will be compatible with Windows 8.
#>
Configuration ScheduledTask_CreateScheduledTasksWeekly_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask ScheduledTaskWeeklyAdd
        {
            TaskName                = 'Test task Weekly'
            TaskPath                = '\MyTasks'
            ActionExecutable        = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType            = 'Weekly'
            WeeksInterval           = 1
            DaysOfWeek              = 'Monday', 'Wednesday', 'Saturday'
            RepeatInterval          = '00:15:00'
            RepetitionDuration      = '08:00:00'
            AllowStartIfOnBatteries = $true
            Compatibility           = 'Win8'
            Hidden                  = $true
        }
    }
}
