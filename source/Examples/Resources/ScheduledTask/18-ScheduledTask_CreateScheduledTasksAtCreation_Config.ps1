<#PSScriptInfo
.VERSION 1.0.0
.GUID c7e3df37-31a5-4034-b593-a1ada74ec3bd
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
        This example creates a scheduled task called 'Test task Creation Modification' in
        the folder task folder 'MyTasks' that starts a new powershell process when the task
        is created or modified. The initial task trigger will be delayed for 10 minutes.
#>
Configuration ScheduledTask_CreateScheduledTasksAtCreation_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask ScheduledTaskAtCreationAdd
        {
            TaskName = 'Test task Creation Modification'
            TaskPath = '\MyTasks'
            Ensure = 'Present'
            ScheduleType = 'AtCreation'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            Delay = '00:10:00'
        }
    }
}
