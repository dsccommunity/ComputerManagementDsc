<#
    .EXAMPLE
    This example creates a scheduled task called 'Test task Weekly' in the folder
    task folder 'MyTasks' that starts a new powershell process every week on
    Monday, Wednesday and Saturday at 00:00 repeating every 15 minutes for 8 hours.
    The task will be hidden and will be allowed to start if the machine is running
    on batteries. The task will be compatible with Windows 8.
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
        xScheduledTask xScheduledTaskWeeklyAdd
        {
            TaskName                = 'Test task Weekly'
            TaskPath                = '\MyTasks'
            ActionExecutable        = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType            = 'Weekly'
            WeeksInterval           = 1
            DaysOfWeek              = 'Monday', 'Wednesday', 'Saturday'
            RepeatInterval          = '00:15:00'
            RepetitionDuration      = '08:00:00'
            AllowStartIfOnBatteries = $true
            Compatibility           = 'Win8'
            Hidden                  = $true
        }
    }
}
