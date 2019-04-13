<#PSScriptInfo
.VERSION 1.0.0
.GUID d5cfbf76-5123-48bb-a856-5ea44504b4eb
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
        This example creates a scheduled task called 'Test task Startup' in the folder
        task folder 'MyTasks' that starts a new powershell process when the machine
        is started up repeating every 15 minutes for 8 hours.
#>
Configuration ScheduledTask_CreateScheduledTasksAtStartup_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask ScheduledTaskStartupAdd
        {
            TaskName           = 'Test task Startup'
            TaskPath           = '\MyTasks'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtStartup'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
        }
    }
}
