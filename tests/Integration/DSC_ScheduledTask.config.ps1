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
            TaskName                  = 'Test task once'
            TaskPath                  = '\ComputerManagementDsc\'
            ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType              = 'Once'
            RepeatInterval            = '00:15:00'
            StartTime                 = '2018-10-01T01:00:00'
            RepetitionDuration        = '08:00:00'
            StopAtDurationEnd         = $false
            TriggerExecutionTimeLimit = '00:00:00'
            ActionWorkingPath         = (Get-Location).Path
            Enable                    = $true
            RandomDelay               = '01:00:00'
            DisallowHardTerminate     = $true
            RunOnlyIfIdle             = $false
            Priority                  = 9
            ExecutionTimeLimit        = '00:00:00'
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
            StartTime                 = '2018-10-01T01:00:00'
            RepetitionDuration        = '08:00:00'
            StopAtDurationEnd         = $false
            RandomDelay               = '01:00:00'
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
        ScheduledTask ScheduledTaskDailyIndefinitelyAdd
        {
            TaskName                  = 'Test task Daily Indefinitely'
            TaskPath                  = '\ComputerManagementDsc\'
            ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType              = 'Daily'
            DaysInterval              = 1
            RepeatInterval            = '00:15:00'
            StartTime                 = '2018-10-01T01:00:00'
            RepetitionDuration        = 'Indefinitely'
            StopAtDurationEnd         = $false
            RandomDelay               = '01:00:00'
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
            StartTime               = '2018-10-01T01:00:00'
            WeeksInterval           = 1
            DaysOfWeek              = 'Monday', 'Wednesday', 'Saturday'
            RepeatInterval          = '00:15:00'
            RepetitionDuration      = '08:00:00'
            StopAtDurationEnd       = $false
            RandomDelay             = '01:00:00'
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
        ScheduledTask ScheduledTaskLogonAdd
        {
            TaskName           = 'Test task Logon'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtLogon'
            StartTime          = '2018-10-01T01:00:00'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $false
            User               = "$ENV:USERNAME"
            Delay              = '00:00:30'
        }
    }
}

Configuration ScheduledTaskStartupAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskStartupAdd
        {
            TaskName           = 'Test task Startup'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtStartup'
            StartTime          = '2018-10-01T01:00:00'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $false
            Delay              = '00:00:30'
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
            -ArgumentList ("$ENV:COMPUTERNAME\$ENV:USERNAME", (ConvertTo-SecureString -String 'Ignore' -AsPlainText -Force))

        ScheduledTask ScheduledTaskExecuteAsAdd
        {
            TaskName            = 'Test task Logon'
            TaskPath            = '\ComputerManagementDsc\'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'AtLogon'
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

        ScheduledTask ScheduledTaskExecuteAsGroupAdd
        {
            TaskName            = 'Test task Logon with BuiltIn Group'
            TaskPath            = '\ComputerManagementDsc\'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            LogonType           = 'Group'
            ExecuteAsCredential = $executeAsCredential
            ScheduleType        = 'AtLogon'
            RunLevel            = 'Limited'
        }
    }
}

Configuration ScheduledTaskOnIdleAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnIdleAdd
        {
            TaskName           = 'Test task OnIdle'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'OnIdle'
            StartTime          = '2018-10-01T01:00:00'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $false
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
            TaskName           = 'Test task OnEvent'
            TaskPath           = '\ComputerManagementDsc\'
            Ensure             = 'Present'
            ScheduleType       = 'OnEvent'
            StartTime          = '2018-10-01T01:00:00'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $false
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments    = '-Command Set-Content -Path c:\temp\seeme.txt -Value ''$(Service) $(DependsOnService) $(ErrorCode) Worked!'''
            EventSubscription  = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''Service Control Manager''] and (Level=2) and (EventID=7001)]]</Select></Query></QueryList>'
            EventValueQueries  = @{
                "Service" = "Event/EventData/Data[@Name='param1']"
                "DependsOnService" = "Event/EventData/Data[@Name='param2']"
                "ErrorCode" = "Event/EventData/Data[@Name='param3']"
            }
            Delay              = '00:00:30'
        }
    }
}

Configuration ScheduledTaskAtCreationAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskAtCreationAdd
        {
            TaskName           = 'Test task AtCreation'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtCreation'
            StartTime          = '2018-10-01T01:00:00'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $false
            Delay              = '00:00:30'
        }
    }
}

Configuration ScheduledTaskOnSessionStateAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnSessionStateAdd
        {
            TaskName           = 'Test task OnSessionState'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'OnSessionState'
            StartTime          = '2018-10-01T01:00:00'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $false
            User               = "$ENV:USERNAME"
            StateChange        = 'OnConnectionFromLocalComputer'
            Delay              = '00:00:30'
        }
    }
}

Configuration ScheduledTaskServiceAccountAdd
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskServiceAccountAdd
        {
            TaskName           = 'Test task BuiltInAccount'
            TaskPath           = '\ComputerManagementDsc\'
            Ensure             = 'Present'
            LogonType          = 'ServiceAccount'
            BuiltInAccount     = 'LOCAL SERVICE'
            RunLevel           = 'Limited'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Once'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = 'Indefinitely'
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
            TaskName                  = 'Test task once'
            TaskPath                  = '\ComputerManagementDsc\'
            ActionExecutable          = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType              = 'Once'
            RepeatInterval            = '00:20:00'
            StartTime                 = '2018-10-01T02:00:00'
            RepetitionDuration        = '08:00:00'
            StopAtDurationEnd         = $true
            RandomDelay               = '02:00:00'
            TriggerExecutionTimeLimit = '02:00:00'
            DisallowDemandStart       = $true
            ExecutionTimeLimit        = '02:00:00'
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
            StartTime          = '2018-10-01T02:00:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            RandomDelay        = '02:00:00'
            Enable             = $false
        }
    }
}

Configuration ScheduledTaskDailyIndefinitelyMod
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskDailyIndefinitelyMod
        {
            TaskName           = 'Test task Daily Indefinitely'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Daily'
            DaysInterval       = 2
            RepeatInterval     = '00:30:00'
            StartTime          = '2018-10-01T02:00:00'
            RepetitionDuration = '10.00:00:00'
            StopAtDurationEnd  = $true
            RandomDelay        = '02:00:00'
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
            StartTime          = '2018-10-01T02:00:00'
            WeeksInterval      = 1
            DaysOfWeek         = 'Monday', 'Thursday', 'Saturday'
            RepeatInterval     = '00:40:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            RandomDelay        = '02:00:00'
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
            StartTime          = '2018-10-01T02:00:00'
            RepeatInterval     = '00:12:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            Delay              = '00:00:45'
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
            ScheduleType       = 'AtLogon'
            User               = "$ENV:USERNAME"
            StartTime          = '2018-10-01T02:00:00'
            RepeatInterval     = '00:10:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            Delay              = '00:00:45'
        }
    }
}

Configuration ScheduledTaskExecuteAsMod
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        $executeAsCredential = New-Object `
            -TypeName System.Management.Automation.PSCredential `
            -ArgumentList ("$ENV:COMPUTERNAME\$ENV:USERNAME", (ConvertTo-SecureString -String 'Ignore' -AsPlainText -Force))

        ScheduledTask ScheduledTaskExecuteAsMod
        {
            TaskName            = 'Test task Logon'
            TaskPath            = '\ComputerManagementDsc\'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType        = 'AtLogon'
            ExecuteAsCredential = $executeAsCredential
            LogonType           = 'Interactive'
            RunLevel            = 'Highest'
        }
    }
}

Configuration ScheduledTaskExecuteAsGroupMod
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        $executeAsCredential = New-Object `
            -TypeName System.Management.Automation.PSCredential `
            -ArgumentList ('Users', (ConvertTo-SecureString -String 'Ignore' -AsPlainText -Force))

        ScheduledTask ScheduledTaskExecuteAsGroupMod
        {
            TaskName            = 'Test task Logon with BuiltIn Group'
            TaskPath            = '\ComputerManagementDsc\'
            ActionExecutable    = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            LogonType           = 'Group'
            ExecuteAsCredential = $executeAsCredential
            ScheduleType        = 'AtLogon'
            RunLevel            = 'Limited'
        }
    }
}

Configuration ScheduledTaskOnIdleMod
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnIdleMod
        {
            TaskName           = 'Test task OnIdle'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'OnIdle'
            StartTime          = '2018-10-01T02:00:00'
            RepeatInterval     = '00:10:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
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
            TaskName           = 'Test task OnEvent'
            TaskPath           = '\ComputerManagementDsc\'
            Ensure             = 'Present'
            ScheduleType       = 'OnEvent'
            StartTime          = '2018-10-01T02:00:00'
            RepeatInterval     = '00:10:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments    = '-Command Set-Content -Path c:\temp\seeme.txt -Value ''$(Service) $(DependsOnService) $(ErrorCode) Worked!'''
            EventSubscription  = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''Service Control Manager''] and (Level=2) and (EventID=7002)]]</Select></Query></QueryList>'
            EventValueQueries  = @{
                "Service" = "Event/EventData/Data[@Name='param1']"
                "DependsOnService" = "Event/EventData/Data[@Name='param2']"
                "ErrorCode" = "Event/EventData/Data[@Name='param3']"
            }
            Delay              = '00:00:45'
        }
    }
}

Configuration ScheduledTaskAtCreationMod
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskAtCreationMod
        {
            TaskName           = 'Test task AtCreation'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtCreation'
            StartTime          = '2018-10-01T02:00:00'
            RepeatInterval     = '00:10:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            Delay              = '00:00:45'
        }
    }
}

Configuration ScheduledTaskOnSessionStateMod
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnSessionStateMod
        {
            TaskName           = 'Test task OnSessionState'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'OnSessionState'
            StartTime          = '2018-10-01T02:00:00'
            RepeatInterval     = '00:10:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            User               = "$ENV:USERNAME"
            StateChange        = 'OnDisconnectFromLocalComputer'
            Delay              = '00:00:45'
        }
    }
}

Configuration ScheduledTaskServiceAccountMod
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskServiceAccountMod
        {
            TaskName           = 'Test task BuiltInAccount'
            TaskPath           = '\ComputerManagementDsc\'
            Ensure             = 'Present'
            LogonType          = 'ServiceAccount'
            BuiltInAccount     = 'NETWORK SERVICE'
            RunLevel           = 'Limited'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Once'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = 'Indefinitely'
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
            StartTime           = '2018-10-01T02:00:00'
            RepetitionDuration  = '08:00:00'
            StopAtDurationEnd   = $true
            RandomDelay         = '02:00:00'
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
            StartTime          = '2018-10-01T02:00:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            RandomDelay        = '02:00:00'
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
        ScheduledTask ScheduledTaskDailyIndefinitelyDel
        {
            TaskName           = 'Test task Daily Indefinitely'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Daily'
            DaysInterval       = 2
            RepeatInterval     = '00:30:00'
            StartTime          = '2018-10-01T02:00:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            RandomDelay        = '02:00:00'
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
            StartTime          = '2018-10-01T02:00:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            RandomDelay        = '02:00:00'
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
            StartTime          = '2018-10-01T02:00:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            Delay              = '00:00:45'
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
            ScheduleType       = 'AtLogon'
            User               = "$ENV:USERNAME"
            RepeatInterval     = '00:10:00'
            StartTime          = '2018-10-01T02:00:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            Delay              = '00:00:45'
            Ensure             = 'Absent'
        }
    }
}

Configuration ScheduledTaskExecuteAsDel
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskExecuteAsDel
        {
            TaskName         = 'Test task Logon'
            TaskPath         = '\ComputerManagementDsc\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType     = 'AtLogon'
            Ensure           = 'Absent'
        }
    }
}

Configuration ScheduledTaskExecuteAsGroupDel
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskExecuteAsGroupDel
        {
            TaskName         = 'Test task Logon with BuiltIn Group'
            TaskPath         = '\ComputerManagementDsc\'
            ActionExecutable = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType     = 'AtLogon'
            Ensure           = 'Absent'
        }
    }
}

Configuration ScheduledTaskOnIdleDel
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnIdleDel
        {
            TaskName           = 'Test task OnIdle'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'OnIdle'
            StartTime          = '2018-10-01T02:00:00'
            RepeatInterval     = '00:10:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            Ensure             = 'Absent'
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
            TaskName           = 'Test task OnEvent'
            TaskPath           = '\ComputerManagementDsc\'
            Ensure             = 'Absent'
            ScheduleType       = 'OnEvent'
            StartTime          = '2018-10-01T02:00:00'
            RepeatInterval     = '00:10:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ActionArguments    = '-Command Set-Content -Path c:\temp\seeme.txt -Value ''$(Service) $(DependsOnService) $(ErrorCode) Worked!'''
            EventSubscription  = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''Service Control Manager''] and (Level=2) and (EventID=7001)]]</Select></Query></QueryList>'
            EventValueQueries  = @{
                "Service" = "Event/EventData/Data[@Name='param1']"
                "DependsOnService" = "Event/EventData/Data[@Name='param2']"
                "ErrorCode" = "Event/EventData/Data[@Name='param3']"
            }
            Delay              = '00:00:45'
        }
    }
}

Configuration ScheduledTaskAtCreationDel
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskAtCreationDel
        {
            TaskName           = 'Test task AtCreation'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'AtCreation'
            StartTime          = '2018-10-01T02:00:00'
            RepeatInterval     = '00:10:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            Delay              = '00:00:45'
            Ensure             = 'Absent'
        }
    }
}

Configuration ScheduledTaskOnSessionStateDel
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskOnSessionStateDel
        {
            TaskName           = 'Test task OnSessionState'
            TaskPath           = '\ComputerManagementDsc\'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'OnSessionState'
            StartTime          = '2018-10-01T02:00:00'
            RepeatInterval     = '00:10:00'
            RepetitionDuration = '08:00:00'
            StopAtDurationEnd  = $true
            User               = "$ENV:USERNAME"
            StateChange        = 'OnDisconnectFromLocalComputer'
            Delay              = '00:00:45'
            Ensure             = 'Absent'
        }
    }
}

Configuration ScheduledTaskServiceAccountDel
{
    Import-DscResource -ModuleName ComputerManagementDsc

    node 'localhost'
    {
        ScheduledTask ScheduledTaskServiceAccountDel
        {
            TaskName           = 'Test task BuiltInAccount'
            TaskPath           = '\ComputerManagementDsc\'
            Ensure             = 'Absent'
            LogonType          = 'ServiceAccount'
            BuiltInAccount     = 'LOCAL SERVICE'
            RunLevel           = 'Limited'
            ActionExecutable   = 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe'
            ScheduleType       = 'Once'
            RepeatInterval     = '00:15:00'
            RepetitionDuration = 'Indefinitely'
            ActionWorkingPath  = (Get-Location).Path
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
