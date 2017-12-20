<#
    .EXAMPLE
    This example creates a scheduled task called 'Test task Daily Indefinitely' in the folder
    task folder 'MyTasks' that starts a new powershell process every day at 00:00 repeating
    every 15 minutes indefinitely.
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
        xScheduledTask xScheduledTaskDailyIndefinitelyAdd
        {
            TaskName           = 'Test task Daily Indefinitely'
            TaskPath           = '\MyTasks'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Daily'
            DaysInterval       = 1
            RepeatInterval     = '00:15:00'
            RepetitionDuration = 'Indefinitely'
        }
    }
}
