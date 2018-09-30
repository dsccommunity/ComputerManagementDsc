<#
    .EXAMPLE
    This example creates a scheduled task called 'Test task Once' in the folder
    task folder 'MyTasks' that starts a new powershell process once at 00:00 repeating
    every 15 minutes for 8 hours. The task is delayed by a random amount up to 1 hour
    each time. The task will run even if the previous task is still running and it
    will prevent hard termintaing of the previously running task instance. The task
    execution will have no time limit.
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
        ScheduledTask ScheduledTaskOnceSynchronizeAcrossTimeZoneEnabled
        {
            TaskName                  = 'Test task sync across time zone enabled'
            TaskPath                  = '\MyTasks\'
            ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType              = 'Once'
            StartTime                 = '2018-10-01T01:00:00'
            SynchronizeAcrossTimeZone = $true
            ActionWorkingPath         = (Get-Location).Path
            Enable                    = $true
        }
    }
}
