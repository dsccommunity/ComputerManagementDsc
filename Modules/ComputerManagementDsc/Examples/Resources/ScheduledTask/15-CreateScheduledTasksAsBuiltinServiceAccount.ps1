<#
    .EXAMPLE
    This example creates a scheduled task called 'TriggerOnServiceFailures' in the folder
    root folder. The task is delayed by exactly 30 seconds each time. The task will run when
    an error event 7001 of source Service Control Manager is generated in the system log.
    When a service crashes, it waits for 30 seconds and then starts a new PowerShell instance,
    in which the file c:\temp\seeme.txt get's created with the value 'Worked!'
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName ComputerManagementDsc

    Node $NodeName
    {
        ScheduledTask ServiceEventManager
        {
            TaskName = 'TaskRunAsNetworkService'
            Ensure = 'Present'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments = '-Command Set-Content -Path c:\temp\seeme.txt -Value ''Worked!'''
            ScheduleType       = 'Once'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '4.00:00:00'
            BuiltInAccount = 'NETWORK SERVICE'
        }
    }
}
