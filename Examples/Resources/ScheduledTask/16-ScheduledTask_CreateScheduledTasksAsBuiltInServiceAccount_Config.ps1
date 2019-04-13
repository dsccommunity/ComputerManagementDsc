<#PSScriptInfo
.VERSION 1.0.0
.GUID a2984c97-f4fc-4936-b5d7-f8ccf726744f
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
        This example creates a scheduled task called 'Test As NetworkService' in
        the folder root folder. The task is set to run every 15 minutes.
        When run the task will start a new PowerShell instance running as the
        builtin user NETWORK SERVICE.
        The PowerShell instance will write the value of $env:USERNAME to the
        file c:\temp\seeme.txt.
        The contents of c:\temp\seeme.txt should be "NETWORK SERVICE".
#>
Configuration ScheduledTask_CreateScheduledTasksAsBuiltInServiceAccount_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask ScheduledTaskAsNetworkService
        {
            TaskName           = 'Test As NetworkService'
            Ensure             = 'Present'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments    = '-Command Set-Content -Path c:\temp\seeme.txt -Value $env:USERNAME -Force'
            ScheduleType       = 'Once'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '4.00:00:00'
            BuiltInAccount     = 'NETWORK SERVICE'
        }
    }
}

