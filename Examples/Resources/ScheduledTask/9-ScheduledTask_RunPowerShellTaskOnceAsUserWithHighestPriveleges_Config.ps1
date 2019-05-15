<#PSScriptInfo
.VERSION 1.0.0
.GUID 718e81fa-c553-4715-8f5d-734fb8a02204
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
        This example creates a scheduled task called 'Test task Run As Highest Privilege'
        in the folder task folder 'MyTasks' that starts a new powershell process once.
        The task will run as the credential passed into the $Credential parameter, running
        with the highest privileges.
#>
Configuration ScheduledTask_RunPowerShellTaskOnceAsUserWithHighestPriveleges_Config
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
            TaskName            = 'Test task Run As Highest Privilege'
            TaskPath            = '\MyTasks'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'Once'
            ActionWorkingPath   = (Get-Location).Path
            Enable              = $true
            ExecuteAsCredential = $Credential
            RunLevel            = 'Highest'
        }
    }
}
