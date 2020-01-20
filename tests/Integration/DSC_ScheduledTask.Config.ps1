Configuration ScheduledTaskOnceCrossTimezone
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnceAdd
        {
            TaskName              = 'Test task once cross timezone'
            TaskPath              = '\ComputerManagementDsc\'
            ActionExecutable      = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType          = 'Once'
            RepeatInterval        = '00:15:00'
            RepetitionDuration    = '23:00:00'
            ActionWorkingPath     = (Get-Location).Path
            Enable                = $true
            RandomDelay           = '01:00:00'
            DisallowHardTerminate = $true
            RunOnlyIfIdle         = $false
            Priority              = 9
            ExecutionTimeLimit    = '00:00:00'
        }
    }
}

Configuration ScheduledTaskOnceSynchronizeAcrossTimeZoneDisabled
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnceSynchronizeAcrossTimeZoneDisabled
        {
            TaskName                  = 'Test task sync across time zone disabled'
            TaskPath                  = '\ComputerManagementDsc\'
            ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType              = 'Once'
            StartTime                 = '2018-10-01T01:00:00'
            SynchronizeAcrossTimeZone = $false
            ActionWorkingPath         = (Get-Location).Path
            Enable                    = $true
        }
    }
}

Configuration ScheduledTaskOnceSynchronizeAcrossTimeZoneEnabled
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnceSynchronizeAcrossTimeZoneEnabled
        {
            TaskName                  = 'Test task sync across time zone enabled'
            TaskPath                  = '\ComputerManagementDsc\'
            ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType              = 'Once'
            StartTime                 = '2018-10-01T01:00:00'
            SynchronizeAcrossTimeZone = $true
            ActionWorkingPath         = (Get-Location).Path
            Enable                    = $true
        }
    }
}

Configuration ScheduledTaskOnceAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnceAdd
        {
            TaskName              = 'Test task once'
            TaskPath              = '\ComputerManagementDsc\'
            ActionExecutable      = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType          = 'Once'
            RepeatInterval        = '00:15:00'
            RepetitionDuration    = '08:00:00'
            ActionWorkingPath     = (Get-Location).Path
            Enable                = $true
            RandomDelay           = '01:00:00'
            DisallowHardTerminate = $true
            RunOnlyIfIdle         = $false
            Priority              = 9
            ExecutionTimeLimit    = '00:00:00'
        }
    }
}

Configuration ScheduledTaskDailyAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskDailyAdd
        {
            TaskName                  = 'Test task Daily'
            TaskPath                  = '\ComputerManagementDsc\'
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

Configuration ScheduledTaskDailyIndefinitelyAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskDailyAdd
        {
            TaskName                  = 'Test task Daily Indefinitely'
            TaskPath                  = '\ComputerManagementDsc\'
            ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType              = 'Daily'
            DaysInterval              = 1
            RepeatInterval            = '00:15:00'
            RepetitionDuration        = 'Indefinitely'
            RestartCount              = 2
            RestartInterval           = '00:05:00'
            RunOnlyIfNetworkAvailable = $true
            WakeToRun                 = $true
        }
    }
}

Configuration ScheduledTaskWeeklyAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskWeeklyAdd
        {
            TaskName                = 'Test task Weekly'
            TaskPath                = '\ComputerManagementDsc\'
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

Configuration ScheduledTaskLogonAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnceAdd
        {
            TaskName           = 'Test task Logon'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtLogOn'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
        }
    }
}

Configuration ScheduledTaskStartupAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnceAdd
        {
            TaskName           = 'Test task Startup'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtStartup'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
        }
    }
}

Configuration ScheduledTaskExecuteAsAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        $executeAsCredential = New-Object `
            -TypeName System.Management.Automation.PSCredential `
            -ArgumentList ($ENV:USERNAME, (ConvertTo-SecureString -String 'Ignore' -AsPlainText -Force))

        ScheduledTask ScheduledTaskExecuteAsAdd
        {
            TaskName            = 'Test task Logon'
            TaskPath            = '\ComputerManagementDsc\'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'AtLogOn'
            ExecuteAsCredential = $executeAsCredential
            LogonType           = 'Interactive'
            RunLevel            = 'Highest'
        }
    }
}

Configuration ScheduledTaskExecuteAsGroupAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        $executeAsCredential = New-Object `
            -TypeName System.Management.Automation.PSCredential `
            -ArgumentList ('Users', (ConvertTo-SecureString -String 'Ignore' -AsPlainText -Force))

        ScheduledTask ScheduledTaskExecuteAsAdd
        {
            TaskName            = 'Test task Logon with BuiltIn Group'
            TaskPath            = '\ComputerManagementDsc\'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            LogonType           = 'Group'
            ExecuteAsCredential = $executeAsCredential
            ScheduleType        = 'AtLogOn'
            RunLevel            = 'Limited'
        }
    }
}

Configuration ScheduledTaskOnEventAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnEventAdd
        {
            TaskName          = 'Test task OnEvent'
            TaskPath          = '\ComputerManagementDsc\'
            Ensure            = 'Present'
            ScheduleType      = 'OnEvent'
            ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments   = '-Command Set-Content -Path c:\temp\seeme.txt -Value ''Worked!'''
            EventSubscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''Service Control Manager''] and (Level=2) and (EventID=7001)]]</Select></Query></QueryList>'
            Delay             = '00:00:30'
        }
    }
}

Configuration ScheduledTaskOnceMod
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnceMod
        {
            TaskName            = 'Test task once'
            TaskPath            = '\ComputerManagementDsc\'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'Once'
            RepeatInterval      = '00:20:00'
            RepetitionDuration  = '08:00:00'
            DisallowDemandStart = $true
            ExecutionTimeLimit  = '02:00:00'
        }
    }
}

Configuration ScheduledTaskDailyMod
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskDailyMod
        {
            TaskName           = 'Test task Daily'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Daily'
            DaysInterval       = 2
            RepeatInterval     = '00:30:00'
            RepetitionDuration = '08:00:00'
            Enable             = $false
        }
    }
}

Configuration ScheduledTaskDailyIndefinitelyMod
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskDailyMod
        {
            TaskName           = 'Test task Daily Indefinitely'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Daily'
            DaysInterval       = 2
            RepeatInterval     = '00:30:00'
            RepetitionDuration = '10.00:00:00'
            Enable             = $false
        }
    }
}

Configuration ScheduledTaskWeeklyMod
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskWeeklyMod
        {
            TaskName           = 'Test task Weekly'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Weekly'
            WeeksInterval      = 1
            DaysOfWeek         = 'Monday', 'Thursday', 'Saturday'
            RepeatInterval     = '00:40:00'
            RepetitionDuration = '08:00:00'
        }
    }
}

Configuration ScheduledTaskLogonMod
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskLogonMod
        {
            TaskName           = 'Test task Logon'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtStartup'
            RepeatInterval     = '00:12:00'
            RepetitionDuration = '08:00:00'
        }
    }
}

Configuration ScheduledTaskStartupMod
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskStartupMod
        {
            TaskName           = 'Test task Startup'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtLogOn'
            RepeatInterval     = '00:10:00'
            RepetitionDuration = '08:00:00'
        }
    }
}

Configuration ScheduledTaskExecuteAsMod
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskExecuteAsMod
        {
            TaskName         = 'Test task Logon'
            TaskPath         = '\ComputerManagementDsc\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType     = 'AtLogOn'
            RunLevel         = 'Limited'
        }
    }
}

Configuration ScheduledTaskExecuteAsGroupMod
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskLogonMod
        {
            TaskName         = 'Test task Logon with BuiltIn Group'
            TaskPath         = '\ComputerManagementDsc\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType     = 'AtLogOn'
            RunLevel         = 'Limited'
        }
    }
}

Configuration ScheduledTaskOnEventMod
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnEventMod
        {
            TaskName          = 'Test task OnEvent'
            TaskPath          = '\ComputerManagementDsc\'
            Ensure            = 'Present'
            ScheduleType      = 'OnEvent'
            ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments   = '-Command Set-Content -Path c:\temp\seeme.txt -Value ''Worked!'''
            EventSubscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''Service Control Manager''] and (Level=2) and (EventID=7002)]]</Select></Query></QueryList>'
            Delay             = '00:00:45'
        }
    }
}

Configuration ScheduledTaskOnceDel
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnceDel
        {
            TaskName            = 'Test task once'
            TaskPath            = '\ComputerManagementDsc\'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'Once'
            RepeatInterval      = '00:20:00'
            RepetitionDuration  = '08:00:00'
            DisallowDemandStart = $true
            Ensure              = 'Absent'
        }
    }
}

Configuration ScheduledTaskDailyDel
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskDailyDel
        {
            TaskName           = 'Test task Daily'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Daily'
            DaysInterval       = 2
            RepeatInterval     = '00:30:00'
            RepetitionDuration = '08:00:00'
            Enable             = $false
            Ensure             = 'Absent'
        }
    }
}

Configuration ScheduledTaskDailyIndefinitelyDel
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskDailyDel
        {
            TaskName           = 'Test task Daily Indefinitely'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Daily'
            DaysInterval       = 2
            RepeatInterval     = '00:30:00'
            RepetitionDuration = '08:00:00'
            Enable             = $false
            Ensure             = 'Absent'
        }
    }
}

Configuration ScheduledTaskWeeklyDel
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskWeeklyDel
        {
            TaskName           = 'Test task Weekly'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Weekly'
            WeeksInterval      = 1
            DaysOfWeek         = 'Monday', 'Thursday', 'Saturday'
            RepeatInterval     = '00:40:00'
            RepetitionDuration = '08:00:00'
            Ensure             = 'Absent'
        }
    }
}

Configuration ScheduledTaskLogonDel
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskLogonDel
        {
            TaskName           = 'Test task Logon'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtStartup'
            RepeatInterval     = '00:12:00'
            RepetitionDuration = '08:00:00'
            Ensure             = 'Absent'
        }
    }
}

Configuration ScheduledTaskStartupDel
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskStartupDel
        {
            TaskName           = 'Test task Startup'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtLogOn'
            RepeatInterval     = '00:10:00'
            RepetitionDuration = '08:00:00'
            Ensure             = 'Absent'
        }
    }
}

Configuration ScheduledTaskExecuteAsDel
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskLogonDel
        {
            TaskName         = 'Test task Logon'
            TaskPath         = '\ComputerManagementDsc\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType     = 'AtLogOn'
            Ensure           = 'Absent'
        }
    }
}

Configuration ScheduledTaskExecuteAsGroupDel
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskLogonDel
        {
            TaskName         = 'Test task Logon with BuiltIn Group'
            TaskPath         = '\ComputerManagementDsc\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType     = 'AtLogOn'
            Ensure           = 'Absent'
        }
    }
}

Configuration ScheduledTaskOnEventDel
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnEventDel
        {
            TaskName          = 'Test task OnEvent'
            TaskPath          = '\ComputerManagementDsc\'
            Ensure            = 'Absent'
            ScheduleType      = 'OnEvent'
            ActionExecutable  = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments   = '-Command Set-Content -Path c:\temp\seeme.txt -Value ''Worked!'''
            EventSubscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''Service Control Manager''] and (Level=2) and (EventID=7001)]]</Select></Query></QueryList>'
            Delay             = '00:00:30'
        }
    }
}

Configuration ScheduledTaskDisableBuiltIn
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskDisableBuiltIn
        {
            TaskName              = 'Test task builtin'
            TaskPath              = '\ComputerManagementDsc\'
            Enable                = $false
        }
    }
}

Configuration ScheduledTaskRemoveBuiltIn
{
    Import-DscResource -ModuleName ComputerManagementDsc
    node 'localhost'
    {
        ScheduledTask ScheduledTaskRemoveBuiltIn
        {
            TaskName              = 'Test task builtin'
            TaskPath              = '\ComputerManagementDsc\'
            Ensure                = 'Absent'
        }
    }
}
