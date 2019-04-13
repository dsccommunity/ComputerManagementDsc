<#PSScriptInfo
.VERSION 1.0.0
.GUID ee32fb99-4150-4616-a46c-d2132ffb5205
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
        This example creates a scheduled task called 'Test task sync across time zone enabled'
        in the folder 'MyTasks' that starts a new powershell process once 2018-10-01 01:00
        The task will have the option Synchronize across time zone enabled.
#>
Configuration ScheduledTask_CreateScheduledTaskOnceSynchronizeAcrossTimeZoneEnabled_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask ScheduledTaskOnceSynchronizeAcrossTimeZoneEnabled
        {
            TaskName                  = 'Test task sync across time zone enabled'
            TaskPath                  = '\MyTasks\'
            ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType              = 'Once'
            StartTime                 = '2018-10-01T01:00:00'
            SynchronizeAcrossTimeZone = $true
            ActionWorkingPath         = (Get-Location).Path
            Enable                    = $true
        }
    }
}
