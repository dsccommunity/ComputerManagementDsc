<#
    .EXAMPLE
    This example creates a scheduled task called 'TaskRunAsNetworkService' in
    the folder root folder. The task is set to run every 15 minutes.
    When run the task will start a new PowerShell instance running as the
    builtin user NETWORK SERVICE.
    The PowerShell instance will write the value of $env:USERNAME to the
    file c:\temp\seeme.txt.
    The contents of c:\temp\seeme.txt should be "NETWORK SERVICE".
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
            TaskName           = 'TaskRunAsNetworkService'
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

