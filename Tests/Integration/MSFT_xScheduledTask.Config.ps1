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
            RepeatInterval = [datetime]::Today.AddMinutes(15)
            RepetitionDuration = [datetime]::Today.AddHours(8)
            ActionWorkingPath = (Get-Location).Path
            Enable = $true
            RandomDelay = [datetime]::Today.AddMinutes(60)
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
            RepeatInterval = [datetime]::Today.AddMinutes(15)
            RepetitionDuration = [datetime]::Today.AddHours(8)
            RestartCount = 2
            RestartInterval = [datetime]::Today.AddMinutes(5)
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
            RepeatInterval = [datetime]::Today.AddMinutes(15)
            RepetitionDuration = [datetime]::Today.AddHours(8)
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
            RepeatInterval = [datetime]::Today.AddMinutes(15)
            RepetitionDuration = [datetime]::Today.AddHours(8)
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
            RepeatInterval = [datetime]::Today.AddMinutes(15)
            RepetitionDuration = [datetime]::Today.AddHours(8)
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
            RepeatInterval = [datetime]::Today.AddMinutes(20)
            RepetitionDuration = [datetime]::Today.AddHours(8)
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
            RepeatInterval = [datetime]::Today.AddMinutes(30)            
            RepetitionDuration = [datetime]::Today.AddHours(8)
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
            RepeatInterval = [datetime]::Today.AddMinutes(40)
            RepetitionDuration = [datetime]::Today.AddHours(8)
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
            RepeatInterval = [datetime]::Today.AddMinutes(12)
            RepetitionDuration = [datetime]::Today.AddHours(8)
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
            RepeatInterval = [datetime]::Today.AddMinutes(10)
            RepetitionDuration = [datetime]::Today.AddHours(8)
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
            RepeatInterval = [datetime]::Today.AddMinutes(20)
            RepetitionDuration = [datetime]::Today.AddHours(8)
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
            RepeatInterval = [datetime]::Today.AddMinutes(30)            
            RepetitionDuration = [datetime]::Today.AddHours(8)
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
            RepeatInterval = [datetime]::Today.AddMinutes(40)
            RepetitionDuration = [datetime]::Today.AddHours(8)
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
            RepeatInterval = [datetime]::Today.AddMinutes(12)
            RepetitionDuration = [datetime]::Today.AddHours(8)
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
            RepeatInterval = [datetime]::Today.AddMinutes(10)
            RepetitionDuration = [datetime]::Today.AddHours(8)
            Ensure = 'Absent'
        }
    }
}
