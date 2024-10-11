<#PSScriptInfo
.VERSION 1.0.0
.GUID eb11e2d6-9b8b-4ca6-a571-d8eb2761e4af
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
        This example creates a scheduled task called 'Test task Session State' in
        the folder task folder 'MyTasks' that starts a new powershell process when the
        session state changes. The task triggers only on connection by the specific user
        'UserName' to the local computer. The initial task trigger will be delayed for 10 minutes.
#>
Configuration ScheduledTask_CreateScheduledTasksOnSessionState_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask ScheduledTaskOnSessionStateAdd
        {
            TaskName = 'Test task Session State'
            TaskPath = '\MyTasks'
            Ensure = 'Present'
            ScheduleType = 'OnSessionState'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            User = 'UserName'
            StateChange = 'OnConnectionFromLocalComputer'
            Delay = '00:10:00'
        }
    }
}
