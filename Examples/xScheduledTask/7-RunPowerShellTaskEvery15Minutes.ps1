<#
    .EXAMPLE
    This example will create a scheduled task that will call PowerShell.exe every 15
    minutes for 4 days to run a script saved locally. The task will start immediately.
    The script will be called as the local system account.
#>
Configuration Example
{
    param
    (
        [Parameter()]
        [System.String[]]
        $NodeName = 'localhost'
    )

    Import-DscResource -ModuleName xComputerManagement

    Node $NodeName
    {
        xScheduledTask MaintenanceScriptExample
        {
          TaskName           = "Custom maintenance tasks"
          ActionExecutable   = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
          ActionArguments    = "-File `"C:\scripts\my custom script.ps1`""
          ScheduleType       = 'Once'
          RepeatInterval     = '00:15:00'
          RepetitionDuration = '4.00:00:00'
        }
    }
}
