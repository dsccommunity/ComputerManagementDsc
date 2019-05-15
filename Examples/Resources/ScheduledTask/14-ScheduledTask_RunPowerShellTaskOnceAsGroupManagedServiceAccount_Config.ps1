<#PSScriptInfo
.VERSION 1.0.0
.GUID cc614ca9-5994-48fb-9528-46107b3eea91
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
        This example creates a scheduled task called 'Test task Run As gMSA'
        in the folder task folder 'MyTasks' that starts a new powershell process once.
        The task will run as the user passed into the ExecuteAsGMSA parameter.
#>
Configuration ScheduledTask_RunPowerShellTaskOnceAsGroupManagedServiceAccount_Config
{
    param
    (
        # Group Managed Service Account must be in the form of DOMAIN\gMSA$ or user@domain.fqdn (UPN)
        [Parameter()]
        [ValidatePattern('^\w+\\\w+\$$|\w+@\w+\.\w+')]
        [System.String]
        $GroupManagedServiceAccount = 'DOMAIN\gMSA$'
    )

    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        ScheduledTask MaintenanceScriptExample
        {
            TaskName            = 'Test task Run As gMSA'
            TaskPath            = '\MyTasks'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'Once'
            ActionWorkingPath   = (Get-Location).Path
            Enable              = $true
            ExecuteAsGMSA       = $GroupManagedServiceAccount
        }
    }
}
