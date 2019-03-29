<#PSScriptInfo
.VERSION 1.0.0
.GUID cff7293a-5b43-491c-9628-d6eca35c8bfd
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
        This example creates a scheduled task called 'TriggerOnServiceFailures' in the folder
        root folder. The task is delayed by exactly 30 seconds each time. The task will run when
        an error event 7001 of source Service Control Manager is generated in the system log.
        When a service crashes, it waits for 30 seconds and then starts a new PowerShell instance,
        in which the file c:\temp\seeme.txt get's created with the value 'Worked!'
#>
Configuration ScheduledTask_CreateScheduledTasksOnEvent_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask ServiceEventManager
        {
            TaskName = 'TriggerOnServiceFailures'
            Ensure = 'Present'
            ScheduleType = 'OnEvent'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments = '-Command Set-Content -Path c:\temp\seeme.txt -Value ''Worked!'''
            EventSubscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''Service Control Manager''] and (Level=2) and (EventID=7001)]]</Select></Query></QueryList>'
            Delay = '00:00:30'
        }
    }
}
