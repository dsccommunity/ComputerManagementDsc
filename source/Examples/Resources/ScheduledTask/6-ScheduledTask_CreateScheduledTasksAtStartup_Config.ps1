<#PSScriptInfo
.VERSION 1.0.0
.GUID d5cfbf76-5123-48bb-a856-5ea44504b4eb
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
        This example creates a scheduled task called 'Test task Startup' in the folder
        task folder 'MyTasks' that starts a new powershell process when the machine
        is started up repeating every 15 minutes for 8 hours. The initial task trigger
        will be delayed for 15 minutes.
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
            Delay              = '00:15:00'
        }
    }
}
