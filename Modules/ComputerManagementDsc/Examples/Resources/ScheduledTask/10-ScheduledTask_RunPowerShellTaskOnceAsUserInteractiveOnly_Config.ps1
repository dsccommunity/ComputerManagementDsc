<#PSScriptInfo
.VERSION 1.0.0
.GUID 0323fac5-e026-4f41-a9be-9fdcd0967b60
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
        This example creates a scheduled task called 'Test task interactive' in the folder
        task folder 'MyTasks' that starts a new powershell process once. The task will
        execute using the credential passed into the $Credential parameter, but only when
        the user contained in the $Credential is logged on.
#>
Configuration ScheduledTask_RunPowerShellTaskOnceAsUserInteractiveOnly_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask MaintenanceScriptExample
        {
            TaskName            = 'Test task Interactive'
            TaskPath            = '\MyTasks'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'Once'
            ActionWorkingPath   = (Get-Location).Path
            Enable              = $true
            ExecuteAsCredential = $Credential
            LogonType           = 'Interactive'
        }
    }
}
