Configuration xScheduledTaskOnceCrossTimezone
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskOnceAdd
        {
            TaskName = 'Test task once cross timezone'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Once'
            RepeatInterval = '00:15:00'
            RepetitionDuration = '23:00:00'
            ActionWorkingPath = (Get-Location).Path
            Enable = $true
            RandomDelay = '01:00:00'
            DisallowHardTerminate = $true
            RunOnlyIfIdle = $false
            Priority = 9
        }
    }
}

Configuration xScheduledTaskOnceAdd
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskOnceAdd
        {
            TaskName = 'Test task once'
            TaskPath = '\xComputerManagement\'
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
    }
}

Configuration xScheduledTaskDailyAdd
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskDailyAdd
        {
            TaskName = 'Test task Daily'
            TaskPath = '\xComputerManagement\'
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
    }
}

Configuration xScheduledTaskDailyIndefinitelyAdd
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskDailyAdd
        {
            TaskName = 'Test task Daily Indefinitely'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Daily'
            DaysInterval = 1
            RepeatInterval = '00:15:00'
            RepetitionDuration = 'Indefinitely'
            RestartCount = 2
            RestartInterval = '00:05:00'
            RunOnlyIfNetworkAvailable = $true
            WakeToRun = $true
        }
    }
}

Configuration xScheduledTaskWeeklyAdd
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskWeeklyAdd
        {
            TaskName = 'Test task Weekly'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Weekly'
            WeeksInterval = 1
            DaysOfWeek = 'Monday', 'Wednesday', 'Saturday'
            RepeatInterval = '00:15:00'
            RepetitionDuration = '08:00:00'
            AllowStartIfOnBatteries = $true
            Compatibility = 'Win8'
            Hidden = $true
        }
    }
}

Configuration xScheduledTaskLogonAdd
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskOnceAdd
        {
            TaskName = 'Test task Logon'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'AtLogOn'
            RepeatInterval = '00:15:00'
            RepetitionDuration = '08:00:00'
        }
    }
}

Configuration xScheduledTaskStartupAdd
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskOnceAdd
        {
            TaskName = 'Test task Startup'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'AtStartup'
            RepeatInterval = '00:15:00'
            RepetitionDuration = '08:00:00'
        }
    }
}

Configuration xScheduledTaskOnceMod
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskOnceMod
        {
            TaskName = 'Test task once'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Once'
            RepeatInterval = '00:20:00'
            RepetitionDuration = '08:00:00'
            DisallowDemandStart = $true
        }
    }
}

Configuration xScheduledTaskDailyMod
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskDailyMod
        {
            TaskName = 'Test task Daily'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Daily'
            DaysInterval = 2
            RepeatInterval = '00:30:00'
            RepetitionDuration = '08:00:00'
            Enable = $false
        }
    }
}

Configuration xScheduledTaskDailyIndefinitelyMod
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskDailyMod
        {
            TaskName = 'Test task Daily Indefinitely'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Daily'
            DaysInterval = 2
            RepeatInterval = '00:30:00'
            RepetitionDuration = '10.00:00:00'
            Enable = $false
        }
    }
}

Configuration xScheduledTaskWeeklyMod
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskWeeklyMod
        {
            TaskName = 'Test task Weekly'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Weekly'
            WeeksInterval = 1
            DaysOfWeek = 'Monday', 'Thursday', 'Saturday'
            RepeatInterval = '00:40:00'
            RepetitionDuration = '08:00:00'
        }
    }
}

Configuration xScheduledTaskLogonMod
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskOnceMod
        {
            TaskName = 'Test task Logon'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'AtStartup'
            RepeatInterval = '00:12:00'
            RepetitionDuration = '08:00:00'
        }
    }
}

Configuration xScheduledTaskStartupMod
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskOnceMod
        {
            TaskName = 'Test task Startup'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'AtLogOn'
            RepeatInterval = '00:10:00'
            RepetitionDuration = '08:00:00'
        }
    }
}

Configuration xScheduledTaskOnceDel
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskOnceDel
        {
            TaskName = 'Test task once'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Once'
            RepeatInterval = '00:20:00'
            RepetitionDuration = '08:00:00'
            DisallowDemandStart = $true
            Ensure = 'Absent'
        }
    }
}

Configuration xScheduledTaskDailyDel
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskDailyDel
        {
            TaskName = 'Test task Daily'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Daily'
            DaysInterval = 2
            RepeatInterval = '00:30:00'
            RepetitionDuration = '08:00:00'
            Enable = $false
            Ensure = 'Absent'
        }
    }
}

Configuration xScheduledTaskDailyIndefinitelyDel
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskDailyDel
        {
            TaskName = 'Test task Daily Indefinitely'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Daily'
            DaysInterval = 2
            RepeatInterval = '00:30:00'
            RepetitionDuration = '08:00:00'
            Enable = $false
            Ensure = 'Absent'
        }
    }
}

Configuration xScheduledTaskWeeklyDel
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskWeeklyDel
        {
            TaskName = 'Test task Weekly'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'Weekly'
            WeeksInterval = 1
            DaysOfWeek = 'Monday', 'Thursday', 'Saturday'
            RepeatInterval = '00:40:00'
            RepetitionDuration = '08:00:00'
            Ensure = 'Absent'
        }
    }
}

Configuration xScheduledTaskLogonDel
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskLogonDel
        {
            TaskName = 'Test task Logon'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'AtStartup'
            RepeatInterval = '00:12:00'
            RepetitionDuration = '08:00:00'
            Ensure = 'Absent'
        }
    }
}

Configuration xScheduledTaskStartupDel
{
    Import-DscResource -ModuleName xComputerManagement
    node 'localhost'
    {
        xScheduledTask xScheduledTaskStartupDel
        {
            TaskName = 'Test task Startup'
            TaskPath = '\xComputerManagement\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType = 'AtLogOn'
            RepeatInterval = '00:10:00'
            RepetitionDuration = '08:00:00'
            Ensure = 'Absent'
        }
    }
}
