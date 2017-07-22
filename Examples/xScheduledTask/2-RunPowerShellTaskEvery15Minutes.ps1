<#
    .EXAMPLE
    This example will create a scheduled task that will call PowerShell.exe every 15
    minutes to run a script saved locally.
    The script will be called as the local system account
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
          RepeatInterval     = [datetime]::Today.AddMinutes(15)
          RepetitionDuration = [datetime]::Today.AddHours(10)
        }
    }
}
