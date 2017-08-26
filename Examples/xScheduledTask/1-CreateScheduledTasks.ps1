<#
    .EXAMPLE
    This example creates five tasks with the following schedules that start a new powershell process
        - Once at 00:00 repeating every 15 minutes for 8 hours
        - Daily at 00:00 repeating every 15 minutes for 8 hours
        - Weekly at 00:00 repeating every 15 minutes for 8 hours on Mon, Wed, Sat
        - At logon repeating every 15 minutes for 8 hours
        - At startup repeating every 15 minutes for 8 hours
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
        xScheduledTask xScheduledTaskOnceAdd
        {
            TaskName = 'Test task once'
            TaskPath = '\MyTasks'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Once'
            RepeatInterval = '00:15:00'
            RepetitionDuration = '08:00:00'
            ActionWorkingPath = (Get-Location).Path
            Enable = $true
            RandomDelay = '01:00:00'
            DisallowHardTerminate = $true
            RunOnlyIfIdle = $false
            Priority = 9
        }

        xScheduledTask xScheduledTaskDailyAdd
        {
            TaskName = 'Test task Daily'
            TaskPath = '\MyTasks'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Daily'
            DaysInterval = 1
            RepeatInterval = '00:15:00'
            RepetitionDuration = '08:00:00'
            RestartCount = 2
            RestartInterval = '00:05:00'
            RunOnlyIfNetworkAvailable = $true
            WakeToRun = $true
        }

        xScheduledTask xScheduledTaskWeeklyAdd
        {
            TaskName = 'Test task Weekly'
            TaskPath = '\MyTasks'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Weekly'
            WeeksInterval = 1
            DaysOfWeek = 'Monday','Wednesday','Saturday'
            RepeatInterval = '00:15:00'
            RepetitionDuration = '08:00:00'
            AllowStartIfOnBatteries = $true
            Compatibility = 'Win8'
            Hidden = $true
        }

        xScheduledTask xScheduledTaskLogonAdd
        {
            TaskName = 'Test task Logon'
            TaskPath = '\MyTasks'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'AtLogOn'
            RepeatInterval = '08:00:00'
            RepetitionDuration = '08:00:00'
        }

        xScheduledTask xScheduledTaskStartupAdd
        {
            TaskName = 'Test task Startup'
            TaskPath = '\MyTasks'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'AtStartup'
            RepeatInterval = '08:00:00'
            RepetitionDuration = '08:00:00'
        }
    }
}
