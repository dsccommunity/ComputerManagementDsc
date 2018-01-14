<#
    .EXAMPLE
    This example creates a scheduled task called 'Test task Daily' in the folder
    task folder 'MyTasks' that starts a new powershell process every day at 00:00 repeating
    every 15 minutes for 8 hours. If the task fails it will be restarted after 5 minutes
    and it will be restarted a maximum of two times. It will only run if the network
    is connected and will wake the machine up to execute the task.
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
        xScheduledTask xScheduledTaskDailyAdd
        {
            TaskName                  = 'Test task Daily'
            TaskPath                  = '\MyTasks'
            ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType              = 'Daily'
            DaysInterval              = 1
            RepeatInterval            = '00:15:00'
            RepetitionDuration        = '08:00:00'
            RestartCount              = 2
            RestartInterval           = '00:05:00'
            RunOnlyIfNetworkAvailable = $true
            WakeToRun                 = $true
        }
    }
}
