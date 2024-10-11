<#PSScriptInfo
.VERSION 1.0.0
.GUID 6a249767-c480-453f-9e10-1ed7ef465d87
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
        This example will create a scheduled task that will call PowerShell.exe every 15
        minutes for 4 days to run a script saved locally. The task will start immediately.
        The script will be called as the local system account. All running tasks will be
        stopped at the end of the repetition duration.
#>
Configuration ScheduledTask_RunPowerShellTaskEvery15Minutes_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask MaintenanceScriptExample
        {
          TaskName           = "Custom maintenance tasks"
          ActionExecutable   = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
          ActionArguments    = "-File `"C:\scripts\my custom script.ps1`""
          ScheduleType       = 'Once'
          RepeatInterval     = '00:15:00'
          RepetitionDuration = '4.00:00:00'
          StopAtDurationEnd  = $true
        }
    }
}
