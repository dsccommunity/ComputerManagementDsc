Configuration Sample_xScheduledTask
{
    Import-DscResource -ModuleName xComputerManagement
    node "localhost"
    {
        xScheduledTask xScheduledTaskOnceAdd
        {
            TaskName = "Test task once"
            TaskPath = "\MyTasks"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ScheduleType = 'Once'
            RepeatInterval = [datetime]::Today.AddMinutes(15)
            RepetitionDuration = [datetime]::Today.AddHours(8)
            ActionWorkingPath = (Get-Location).Path
            Enable = $true
            RandomDelay = [datetime]::Today.AddMinutes(60)
            DisallowHardTerminate = $true
            RunOnlyIfIdle = $false
            Priority = 9
        }
    
        xScheduledTask xScheduledTaskDailyAdd
        {
            TaskName = "Test task Daily"
            TaskPath = "\MyTasks"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ScheduleType = 'Daily'
            DaysInterval = 1
            RepeatInterval = [datetime]::Today.AddMinutes(15)
            RepetitionDuration = [datetime]::Today.AddHours(8)
            RestartCount = 2
            RestartInterval = [datetime]::Today.AddMinutes(5)
            RunOnlyIfNetworkAvailable = $true
            WakeToRun = $true
        }
    
        xScheduledTask xScheduledTaskWeeklyAdd
        {
            TaskName = "Test task Weekly"
            TaskPath = "\MyTasks"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ScheduleType = 'Weekly'
            WeeksInterval = 1
            DaysOfWeek = 'Monday','Wednesday','Saturday'
            RepeatInterval = [datetime]::Today.AddMinutes(15)
            RepetitionDuration = [datetime]::Today.AddHours(8)
            AllowStartIfOnBatteries = $true
            Compatibility = 'Win8'
            Hidden = $true
        }
    
        xScheduledTask xScheduledTaskOnceAdd
        {
            TaskName = "Test task Logon"
            TaskPath = "\MyTasks"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ScheduleType = 'AtLogOn'
            RepeatInterval = [datetime]::Today.AddMinutes(15)
            RepetitionDuration = [datetime]::Today.AddHours(8)
        }
  
        xScheduledTask xScheduledTaskOnceAdd
        {
            TaskName = "Test task Startup"
            TaskPath = "\MyTasks"
            ActionExecutable = "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe"
            ScheduleType = 'AtStartup'
            RepeatInterval = [datetime]::Today.AddMinutes(15)
            RepetitionDuration = [datetime]::Today.AddHours(8)
        }
    }
}

Sample_xScheduledTask
Start-DscConfiguration -Path Sample_xScheduledTask -Wait -Verbose -Force
