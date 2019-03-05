<#PSScriptInfo
.VERSION 1.0.0
.GUID dffe47fd-73f7-47d2-8604-f381e6c18f26
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
        This example will create a scheduled task that will call PowerShell.exe every 15
        minutes indefinitely to run a script saved locally. The task will start immediately.
        The script will be called as the local system account.
#>
Configuration ScheduledTask_RunPowerShellTaskEvery15MinutesIndefinitely_Config
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
          RepetitionDuration = 'Indefinitely'
        }
    }
}
