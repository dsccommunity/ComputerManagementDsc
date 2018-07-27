<#
    .EXAMPLE
    This example creates a scheduled task called 'Test task Run As gMSA'
    in the folder task folder 'MyTasks' that starts a new powershell process once.
    The task will run as the user passed into the ExecuteAsGMSA parameter.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost',

        # Group Managed Service Account must be in the form of DOMAIN\gMSA$ or user@domain.fqdn (UPN)
        [Parameter()]
        [ValidatePattern('^\w+\\\w+\$$|\w+@\w+\.\w+')]
        [System.String]
        $GroupManagedServiceAccount = 'DOMAIN\gMSA$'
    )

    Import-DscResource -ModuleName ComputerManagementDsc

    Node $NodeName
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
