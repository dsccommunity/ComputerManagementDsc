Add-Type -TypeDefinition @'
namespace xScheduledTask
{
    public enum DaysOfWeek
    {
        Sunday = 1,
        Monday = 2,
        Tuesday = 4,
        Wednesday = 8,
        Thursday = 16,
        Friday = 32,
        Saturday = 64
    }
}
'@

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath 'CommonResourceHelper.psm1')

<#
.SYNOPSIS
    Gets the current resource state
.PARAMETER TaskName
    The name of the task
.PARAMETER TaskPath
    The path to the task - defaults to the root directory
.PARAMETER Description
    The task description
.PARAMETER ActionExecutable
    The path to the .exe for this task
.PARAMETER ActionArguments
    The arguments to pass the executable
.PARAMETER ActionWorkingPath
    The working path to specify for the executable
.PARAMETER ScheduleType
    When should the task be executed
.PARAMETER RepeatInterval
    How many units (minutes, hours, days) between each run of this task?
.PARAMETER StartTime
    The time of day this task should start at - defaults to 12:00 AM. Not valid for AtLogon and AtStartup tasks
.PARAMETER Ensure
    Present if the task should exist, Absent if it should be removed
.PARAMETER Enable
    True if the task should be enabled, false if it should be disabled
.PARAMETER ExecuteAsCredential
    The credential this task should execute as. If not specified defaults to running as the local system account
.PARAMETER DaysInterval
    Specifies the interval between the days in the schedule. An interval of 1 produces a daily schedule. An interval of 2 produces an every-other day schedule.
.PARAMETER RandomDelay
    Specifies a random amount of time to delay the start time of the trigger. The delay time is a random time between the time the task triggers and the time that you specify in this setting.
.PARAMETER RepetitionDuration
    Specifies how long the repetition pattern repeats after the task starts.
.PARAMETER DaysOfWeek
    Specifies an array of the days of the week on which Task Scheduler runs the task.
.PARAMETER WeeksInterval
    Specifies the interval between the weeks in the schedule. An interval of 1 produces a weekly schedule. An interval of 2 produces an every-other week schedule.
.PARAMETER User
    Specifies the identifier of the user for a trigger that starts a task when a user logs on.
.PARAMETER DisallowDemandStart
    Indicates whether the task is prohibited to run on demand or not. Defaults to $false
.PARAMETER DisallowHardTerminate
    Indicates whether the task is prohibited to be terminated or not. Defaults to $false
.PARAMETER Compatibility
    The task compatibility level. Defaults to Vista.
.PARAMETER AllowStartIfOnBatteries
    Indicates whether the task should start if the machine is on batteries or not. Defaults to $false
.PARAMETER Hidden
    Indicates that the task is hidden in the Task Scheduler UI.
.PARAMETER RunOnlyIfIdle
    Indicates that Task Scheduler runs the task only when the computer is idle.
.PARAMETER IdleWaitTimeout
    Specifies the amount of time that Task Scheduler waits for an idle condition to occur.
.PARAMETER NetworkName
    Specifies the name of a network profile that Task Scheduler uses to determine if the task can run.
    The Task Scheduler UI uses this setting for display purposes. Specify a network name if you specify the RunOnlyIfNetworkAvailable parameter.
.PARAMETER DisallowStartOnRemoteAppSession
    Indicates that the task does not start if the task is triggered to run in a Remote Applications Integrated Locally (RAIL) session.
.PARAMETER StartWhenAvailable
    Indicates that Task Scheduler can start the task at any time after its scheduled time has passed.
.PARAMETER DontStopIfGoingOnBatteries
    Indicates that the task does not stop if the computer switches to battery power.
.PARAMETER WakeToRun
    Indicates that Task Scheduler wakes the computer before it runs the task.
.PARAMETER IdleDuration
    Specifies the amount of time that the computer must be in an idle state before Task Scheduler runs the task.
.PARAMETER RestartOnIdle
    Indicates that Task Scheduler restarts the task when the computer cycles into an idle condition more than once.
.PARAMETER DontStopOnIdleEnd
    Indicates that Task Scheduler does not terminate the task if the idle condition ends before the task is completed.
.PARAMETER ExecutionTimeLimit
    Specifies the amount of time that Task Scheduler is allowed to complete the task.
.PARAMETER MultipleInstances
    Specifies the policy that defines how Task Scheduler handles multiple instances of the task.
.PARAMETER Priority
    Specifies the priority level of the task. Priority must be an integer from 0 (highest priority) to 10 (lowest priority).
    The default value is 7. Priority levels 7 and 8 are used for background tasks. Priority levels 4, 5, and 6 are used for interactive tasks.
.PARAMETER RestartCount
    Specifies the number of times that Task Scheduler attempts to restart the task.
.PARAMETER RestartInterval
    Specifies the amount of time that Task Scheduler attempts to restart the task.
.PARAMETER RunOnlyIfNetworkAvailable
    Indicates that Task Scheduler runs the task only when a network is available. Task Scheduler uses the NetworkID
    parameter and NetworkName parameter that you specify in this cmdlet to determine if the network is available.
#>
function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskName,
        
        [Parameter()]
        [System.String]
        $TaskPath = '\',

        [Parameter()]
        [System.String]
        $Description,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        $ActionExecutable,
        
        [Parameter()]
        [System.String]
        $ActionArguments,
        
        [Parameter()]
        [System.String]
        $ActionWorkingPath,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet('Once', 'Daily', 'Weekly', 'AtStartup', 'AtLogOn')]
        $ScheduleType,
        
        [Parameter()]
        [System.DateTime]
        $RepeatInterval = [System.DateTime] '00:00:00',
        
        [Parameter()]
        [System.DateTime]
        $StartTime = [System.DateTime]::Today,
        
        [Parameter()]
        [System.String]
        [ValidateSet('Present', 'Absent')]
        $Ensure = 'Present',
        
        [Parameter()]
        [System.Boolean]
        $Enable = $true,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ExecuteAsCredential,

        [Parameter()]
        [System.UInt32]
        $DaysInterval = 1,

        [Parameter()]
        [System.DateTime]
        $RandomDelay = [System.DateTime] '00:00:00',

        [Parameter()]
        [System.DateTime]
        $RepetitionDuration = [System.DateTime] '00:00:00',

        [Parameter()]
        [System.String[]]
        $DaysOfWeek,

        [Parameter()]
        [System.UInt32]
        $WeeksInterval = 1,

        [Parameter()]
        [System.String]
        $User,

        [Parameter()]
        [System.Boolean]
        $DisallowDemandStart = $false,

        [Parameter()]
        [System.Boolean]
        $DisallowHardTerminate = $false,

        [Parameter()]
        [ValidateSet('AT', 'V1', 'Vista', 'Win7', 'Win8')]
        [System.String]
        $Compatibility = 'Vista',

        [Parameter()]
        [System.Boolean]
        $AllowStartIfOnBatteries = $false,

        [Parameter()]
        [System.Boolean]
        $Hidden = $false,

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfIdle = $false,

        [Parameter()]
        [System.DateTime]
        $IdleWaitTimeout = [System.DateTime] '02:00:00',

        [Parameter()]
        [System.String]
        $NetworkName,

        [Parameter()]
        [System.Boolean]
        $DisallowStartOnRemoteAppSession = $false,

        [Parameter()]
        [System.Boolean]
        $StartWhenAvailable = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopIfGoingOnBatteries = $false,

        [Parameter()]
        [System.Boolean]
        $WakeToRun = $false,

        [Parameter()]
        [System.DateTime]
        $IdleDuration = [System.DateTime] '01:00:00',

        [Parameter()]
        [System.Boolean]
        $RestartOnIdle = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopOnIdleEnd = $false,

        [Parameter()]
        [System.DateTime]
        $ExecutionTimeLimit = [System.DateTime] '8:00:00',

        [Parameter()]
        [ValidateSet('IgnoreNew', 'Parallel', 'Queue')]
        [System.String]
        $MultipleInstances = 'Queue',

        [Parameter()]
        [System.UInt32]
        $Priority = 7,

        [Parameter()]
        [System.UInt32]
        $RestartCount = 0,

        [Parameter()]
        [System.DateTime]
        $RestartInterval = [System.DateTime] '00:00:00',

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfNetworkAvailable = $false
    )

    Write-Verbose -Message ('Retrieving existing task ({0} in {1})' -f $TaskName, $TaskPath)
    $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
    
    if ($null -eq $task) 
    {
        Write-Verbose -Message ('No task found. returning empty task {0} with Ensure = "Absent"' -f $Taskname)
        return @{
            TaskName = $TaskName
            ActionExecutable = $ActionExecutable
            Ensure = 'Absent'
            ScheduleType = $ScheduleType
        }
    } 
    else 
    {
        Write-Verbose -Message ('Task {0} found in {1}. Retrieving settings, first action, first trigger and repetition settings' -f $TaskName, $TaskPath)
        $action = $task.Actions | Select-Object -First 1
        $trigger = $task.Triggers | Select-Object -First 1
        $settings = $task.Settings
        $returnScheduleType = 'Unknown'
        $returnInveral = 0

        switch ($trigger.CimClass.CimClassName)
        {
            'MSFT_TaskTimeTrigger'
            {
                $returnScheduleType = 'Once'
                break
            }
            'MSFT_TaskDailyTrigger'
            {
                $returnScheduleType = 'Daily'
                break
            }
            
            'MSFT_TaskWeeklyTrigger'
            {
                $returnScheduleType = 'Weekly'
                break
            }
            
            'MSFT_TaskBootTrigger'
            {
                $returnScheduleType = 'AtStartup'
                break
            }
            
            'MSFT_TaskLogonTrigger'
            {
                $returnScheduleType = 'AtLogon'
                break
            }

            default
            {
                New-InvalidArgumentException -Message "Trigger type $_ not recognized." -ArgumentName CimClassName
            }            
        }
        
        Write-Verbose -Message ('Detected schedule type {0} for first trigger' -f $returnScheduleType)
        
        Write-Verbose -Message 'Calculating timespans/datetimes from trigger repetition settings'

        $repInterval = $trigger.Repetition.Interval
        $Days = $Hours = $Minutes = $Seconds = 0

        if ($repInterval -match 'P(?<Days>\d{0,3})D')
        {
            $Days = $matches.Days
        }

        if ($repInterval -match '(?<Hours>\d{0,2})H')
        {
            $Hours = $matches.Hours
        }

        if ($repInterval -match '(?<Minutes>\d{0,2})M')
        {
            $Minutes = $matches.Minutes
        }

        if ($repInterval -match '(?<Seconds>\d{0,2})S')
        {
            $Seconds = $matches.Seconds
        }
        
        $returnInveral = New-TimeSpan -Days $Days -Hours $Hours -Minutes $Minutes -Seconds $seconds

        $repDuration = $trigger.Repetition.Duration
        $Days = $Hours = $Minutes = $Seconds = 0

        if ($repDuration -match 'P(?<Days>\d{0,3})D')
        {
            $Days = $matches.Days
        }

        if ($repDuration -match '(?<Hours>\d{0,2})H')
        {
            $Hours = $matches.Hours
        }

        if ($repDuration -match '(?<Minutes>\d{0,2})M')
        {
            $Minutes = $matches.Minutes
        }

        if ($repDuration -match '(?<Seconds>\d{0,2})S')
        {
            $Seconds = $matches.Seconds
        }
        
        $repetitionDurationReturn = New-TimeSpan -Days $Days -Hours $Hours -Minutes $Minutes -Seconds $seconds

        $resInterval = $settings.RestartInterval
        $Days = $Hours = $Minutes = $Seconds = 0

        if ($resInterval -match 'P(?<Days>\d{0,3})D')
        {
            $Days = $matches.Days
        }

        if ($resInterval -match '(?<Hours>\d{0,2})H')
        {
            $Hours = $matches.Hours
        }
        
        if ($resInterval -match '(?<Minutes>\d{0,2})M')
        {
            $Minutes = $matches.Minutes
        }

        if ($resInterval -match '(?<Seconds>\d{0,2})S')
        {
            $Seconds = $matches.Seconds
        }
        
        $restartIntervalReturn = New-TimeSpan -Days $Days -Hours $Hours -Minutes $Minutes -Seconds $seconds

        $exeLim = $settings.ExecutionTimeLimit
        $Days = $Hours = $Minutes = $Seconds = 0

        if ($exeLim -match 'P(?<Days>\d{0,3})D')
        {
            $Days = $matches.Days
        }

        if ($exeLim -match '(?<Hours>\d{0,2})H')
        {
            $Hours = $matches.Hours
        }

        if ($exeLim -match '(?<Minutes>\d{0,2})M')
        {
            $Minutes = $matches.Minutes
        }

        if ($exeLim -match '(?<Seconds>\d{0,2})S')
        {
            $Seconds = $matches.Seconds
        }
        
        $executionTimeLimitReturn = New-TimeSpan -Days $Days -Hours $Hours -Minutes $Minutes -Seconds $seconds

        $idleDur = $settings.IdleSettings.IdleDuration
        $Days = $Hours = $Minutes = $Seconds = 0

        if ($idleDur -match 'P(?<Days>\d{0,3})D')
        {
            $Days = $matches.Days
        }

        if ($idleDur -match '(?<Hours>\d{0,2})H')
        {
            $Hours = $matches.Hours
        }

        if ($idleDur -match '(?<Minutes>\d{0,2})M')
        {
            $Minutes = $matches.Minutes
        }

        if ($idleDur -match '(?<Seconds>\d{0,2})S')
        {
            $Seconds = $matches.Seconds
        }
        
        $idleDurationReturn = New-TimeSpan -Days $Days -Hours $Hours -Minutes $Minutes -Seconds $seconds

        $idleWait = $settings.IdleSettings.IdleWaitTimeout
        $Days = $Hours = $Minutes = $Seconds = 0

        if ($idleWait -match 'P(?<Days>\d{0,3})D')
        {
            $Days = $matches.Days
        }

        if ($idleWait -match '(?<Hours>\d{0,2})H')
        {
            $Hours = $matches.Hours
        }

        if ($idleWait -match '(?<Minutes>\d{0,2})M')
        {
            $Minutes = $matches.Minutes
        }

        if ($idleWait -match '(?<Seconds>\d{0,2})S')
        {
            $Seconds = $matches.Seconds
        }
        
        $idleWaitTimeoutReturn = New-TimeSpan -Days $Days -Hours $Hours -Minutes $Minutes -Seconds $seconds

        $rndDelay = $trigger.RandomDelay
        $Days = $Hours = $Minutes = $Seconds = 0

        if ($rndDelay -match 'P(?<Days>\d{0,3})D')
        {
            $Days = $matches.Days
        }

        if ($rndDelay -match '(?<Hours>\d{0,2})H')
        {
            $Hours = $matches.Hours
        }

        if ($rndDelay -match '(?<Minutes>\d{0,2})M')
        {
            $Minutes = $matches.Minutes
        }

        if ($rndDelay -match '(?<Seconds>\d{0,2})S')
        {
            $Seconds = $matches.Seconds
        }
        
        $randomDelayReturn = New-TimeSpan -Days $Days -Hours $Hours -Minutes $Minutes -Seconds $seconds
        
        $DaysOfWeek = @()
        foreach ($binaryAdductor in 1, 2, 4, 8, 16, 32, 64)
        {
            $Day = $trigger.DaysOfWeek -band $binaryAdductor
            if ($Day -ne 0)
            {
                $DaysOfWeek += [xScheduledTask.DaysOfWeek] $Day
            }
        }

        $startAt = $trigger.StartBoundary

        if ($startAt)
        {
            $startAt = [System.DateTime] $startAt
        }
        else
        {
            $startAt = $StartTime
        }
        
        return @{
            TaskName = $TaskName
            TaskPath = $TaskPath
            StartTime = $startAt
            Ensure = 'Present'
            Description = $task.Description
            ActionExecutable = $action.Execute
            ActionArguments = $action.Arguments
            ActionWorkingPath = $action.WorkingDirectory
            ScheduleType = $returnScheduleType
            RepeatInterval = [System.DateTime]::Today.Add($returnInveral)
            ExecuteAsCredential = $task.Principal.UserId
            Enable = $settings.Enabled
            DaysInterval = $trigger.DaysInterval
            RandomDelay = [System.DateTime]::Today.Add($randomDelayReturn)
            RepetitionDuration = [System.DateTime]::Today.Add($repetitionDurationReturn)
            DaysOfWeek = $DaysOfWeek
            WeeksInterval = $trigger.WeeksInterval
            User = $task.Principal.UserId
            DisallowDemandStart = -not $settings.AllowDemandStart
            DisallowHardTerminate = -not $settings.AllowHardTerminate
            Compatibility = $settings.Compatibility
            AllowStartIfOnBatteries = -not $settings.DisallowStartIfOnBatteries
            Hidden = $settings.Hidden
            RunOnlyIfIdle = $settings.RunOnlyIfIdle
            IdleWaitTimeout = $idleWaitTimeoutReturn
            NetworkName = $settings.NetworkSettings.Name
            DisallowStartOnRemoteAppSession = $settings.DisallowStartOnRemoteAppSession
            StartWhenAvailable = $settings.StartWhenAvailable
            DontStopIfGoingOnBatteries = -not $settings.StopIfGoingOnBatteries
            WakeToRun = $settings.WakeToRun
            IdleDuration = [System.DateTime]::Today.Add($idleDurationReturn)
            RestartOnIdle = $settings.IdleSettings.RestartOnIdle
            DontStopOnIdleEnd = -not $settings.IdleSettings.StopOnIdleEnd
            ExecutionTimeLimit = [System.DateTime]::Today.Add($executionTimeLimitReturn)
            MultipleInstances = $settings.MultipleInstances
            Priority = $settings.Priority
            RestartCount = $settings.RestartCount
            RestartInterval = [System.DateTime]::Today.Add($restartIntervalReturn)
            RunOnlyIfNetworkAvailable = $settings.RunOnlyIfNetworkAvailable
        }
    }
}

<#
.SYNOPSIS
    Applies the desired resource state
.PARAMETER TaskName
    The name of the task
.PARAMETER TaskPath
    The path to the task - defaults to the root directory
.PARAMETER Description
    The task description
.PARAMETER ActionExecutable
    The path to the .exe for this task
.PARAMETER ActionArguments
    The arguments to pass the executable
.PARAMETER ActionWorkingPath
    The working path to specify for the executable
.PARAMETER ScheduleType
    When should the task be executed
.PARAMETER RepeatInterval
    How many units (minutes, hours, days) between each run of this task?
.PARAMETER StartTime
    The time of day this task should start at - defaults to 12:00 AM. Not valid for AtLogon and AtStartup tasks
.PARAMETER Ensure
    Present if the task should exist, Absent if it should be removed
.PARAMETER Enable
    True if the task should be enabled, false if it should be disabled
.PARAMETER ExecuteAsCredential
    The credential this task should execute as. If not specified defaults to running as the local system account
.PARAMETER DaysInterval
    Specifies the interval between the days in the schedule. An interval of 1 produces a daily schedule. An interval of 2 produces an every-other day schedule.
.PARAMETER RandomDelay
    Specifies a random amount of time to delay the start time of the trigger. The delay time is a random time between the time the task triggers and the time that you specify in this setting.
.PARAMETER RepetitionDuration
    Specifies how long the repetition pattern repeats after the task starts.
.PARAMETER DaysOfWeek
    Specifies an array of the days of the week on which Task Scheduler runs the task.
.PARAMETER WeeksInterval
    Specifies the interval between the weeks in the schedule. An interval of 1 produces a weekly schedule. An interval of 2 produces an every-other week schedule.
.PARAMETER User
    Specifies the identifier of the user for a trigger that starts a task when a user logs on.
.PARAMETER DisallowDemandStart
    Indicates whether the task is prohibited to run on demand or not. Defaults to $false
.PARAMETER DisallowHardTerminate
    Indicates whether the task is prohibited to be terminated or not. Defaults to $false
.PARAMETER Compatibility
    The task compatibility level. Defaults to Vista.
.PARAMETER AllowStartIfOnBatteries
    Indicates whether the task should start if the machine is on batteries or not. Defaults to $false
.PARAMETER Hidden
    Indicates that the task is hidden in the Task Scheduler UI.
.PARAMETER RunOnlyIfIdle
    Indicates that Task Scheduler runs the task only when the computer is idle.
.PARAMETER IdleWaitTimeout
    Specifies the amount of time that Task Scheduler waits for an idle condition to occur.
.PARAMETER NetworkName
    Specifies the name of a network profile that Task Scheduler uses to determine if the task can run.
    The Task Scheduler UI uses this setting for display purposes. Specify a network name if you specify the RunOnlyIfNetworkAvailable parameter.
.PARAMETER DisallowStartOnRemoteAppSession
    Indicates that the task does not start if the task is triggered to run in a Remote Applications Integrated Locally (RAIL) session.
.PARAMETER StartWhenAvailable
    Indicates that Task Scheduler can start the task at any time after its scheduled time has passed.
.PARAMETER DontStopIfGoingOnBatteries
    Indicates that the task does not stop if the computer switches to battery power.
.PARAMETER WakeToRun
    Indicates that Task Scheduler wakes the computer before it runs the task.
.PARAMETER IdleDuration
    Specifies the amount of time that the computer must be in an idle state before Task Scheduler runs the task.
.PARAMETER RestartOnIdle
    Indicates that Task Scheduler restarts the task when the computer cycles into an idle condition more than once.
.PARAMETER DontStopOnIdleEnd
    Indicates that Task Scheduler does not terminate the task if the idle condition ends before the task is completed.
.PARAMETER ExecutionTimeLimit
    Specifies the amount of time that Task Scheduler is allowed to complete the task.
.PARAMETER MultipleInstances
    Specifies the policy that defines how Task Scheduler handles multiple instances of the task.
.PARAMETER Priority
    Specifies the priority level of the task. Priority must be an integer from 0 (highest priority) to 10 (lowest priority).
    The default value is 7. Priority levels 7 and 8 are used for background tasks. Priority levels 4, 5, and 6 are used for interactive tasks.
.PARAMETER RestartCount
    Specifies the number of times that Task Scheduler attempts to restart the task.
.PARAMETER RestartInterval
    Specifies the amount of time that Task Scheduler attempts to restart the task.
.PARAMETER RunOnlyIfNetworkAvailable
    Indicates that Task Scheduler runs the task only when a network is available. Task Scheduler uses the NetworkID
    parameter and NetworkName parameter that you specify in this cmdlet to determine if the network is available.
#>
function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskName,
        
        [Parameter()]
        [System.String]
        $TaskPath = '\',

        [Parameter()]
        [System.String]
        $Description,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        $ActionExecutable,
        
        [Parameter()]
        [System.String]
        $ActionArguments,
        
        [Parameter()]
        [System.String]
        $ActionWorkingPath,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet('Once', 'Daily', 'Weekly', 'AtStartup', 'AtLogOn')]
        $ScheduleType,
        
        [Parameter()]
        [System.DateTime]
        $RepeatInterval = [System.DateTime] '00:00:00',
        
        [Parameter()]
        [System.DateTime]
        $StartTime = [System.DateTime]::Today,
        
        [Parameter()]
        [System.String]
        [ValidateSet('Present', 'Absent')]
        $Ensure = 'Present',
        
        [Parameter()]
        [System.Boolean]
        $Enable = $true,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ExecuteAsCredential,

        [Parameter()]
        [System.UInt32]
        $DaysInterval = 1,

        [Parameter()]
        [System.DateTime]
        $RandomDelay = [System.DateTime] '00:00:00',

        [Parameter()]
        [System.DateTime]
        $RepetitionDuration = [System.DateTime] '00:00:00',

        [Parameter()]
        [System.String[]]
        $DaysOfWeek,

        [Parameter()]
        [System.UInt32]
        $WeeksInterval = 1,

        [Parameter()]
        [System.String]
        $User,

        [Parameter()]
        [System.Boolean]
        $DisallowDemandStart = $false,

        [Parameter()]
        [System.Boolean]
        $DisallowHardTerminate = $false,

        [Parameter()]
        [ValidateSet('AT', 'V1', 'Vista', 'Win7', 'Win8')]
        [System.String]
        $Compatibility = 'Vista',

        [Parameter()]
        [System.Boolean]
        $AllowStartIfOnBatteries = $false,

        [Parameter()]
        [System.Boolean]
        $Hidden = $false,

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfIdle = $false,

        [Parameter()]
        [System.DateTime]
        $IdleWaitTimeout = [System.DateTime] '02:00:00',

        [Parameter()]
        [System.String]
        $NetworkName,

        [Parameter()]
        [System.Boolean]
        $DisallowStartOnRemoteAppSession = $false,

        [Parameter()]
        [System.Boolean]
        $StartWhenAvailable = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopIfGoingOnBatteries = $false,

        [Parameter()]
        [System.Boolean]
        $WakeToRun = $false,

        [Parameter()]
        [System.DateTime]
        $IdleDuration = [System.DateTime] '01:00:00',

        [Parameter()]
        [System.Boolean]
        $RestartOnIdle = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopOnIdleEnd = $false,

        [Parameter()]
        [System.DateTime]
        $ExecutionTimeLimit = [System.DateTime] '8:00:00',

        [Parameter()]
        [ValidateSet('IgnoreNew', 'Parallel', 'Queue')]
        [System.String]
        $MultipleInstances = 'Queue',

        [Parameter()]
        [System.UInt32]
        $Priority = 7,

        [Parameter()]
        [System.UInt32]
        $RestartCount = 0,

        [Parameter()]
        [System.DateTime]
        $RestartInterval = [System.DateTime] '00:00:00',

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfNetworkAvailable = $false
    )
    
    Write-Verbose -Message ('Entering Set-TargetResource for {0} in {1}' -f $TaskName, $TaskPath)
    $currentValues = Get-TargetResource @PSBoundParameters
    
    if ($Ensure -eq 'Present') 
    {
        if ($RepetitionDuration.TimeOfDay -lt $RepeatInterval.TimeOfDay)
        {
            $exceptionMessage = 'Repetition duration {0} is less than repetition interval {1}. Please set RepeatInterval to a value lower or equal to RepetitionDuration' -f $RepetitionDuration.TimeOfDay, $RepeatInterval.TimeOfDay
            New-InvalidArgumentException -Message $exceptionMessage -ArgumentName RepeatInterval
        }

        if ($ScheduleType -eq 'Daily' -and $DaysInterval -eq 0)
        {
            $exceptionMessage = 'Schedules of the type Daily must have a DaysInterval greater than 0 (value entered: {0})' -f $DaysInterval
            New-InvalidArgumentException -Message $exceptionMessage -ArgumentName DaysInterval
        }

        if ($ScheduleType -eq 'Weekly' -and $WeeksInterval -eq 0)
        {
            $exceptionMessage = 'Schedules of the type Weekly must have a WeeksInterval greater than 0 (value entered: {0})' -f $WeeksInterval
            New-InvalidArgumentException -Message $exceptionMessage -ArgumentName WeeksInterval
        }

        if ($ScheduleType -eq 'Weekly' -and $DaysOfWeek.Count -eq 0)
        {
            $exceptionMessage = 'Schedules of the type Weekly must have at least one weekday selected'
            New-InvalidArgumentException -Message $exceptionMessage -ArgumentName DaysOfWeek
        }

        $actionArgs = @{
            Execute = $ActionExecutable
        }

        if ($ActionArguments) 
        { 
            $actionArgs.Add('Argument', $ActionArguments)
        }

        if ($ActionWorkingPath) 
        { 
            $actionArgs.Add('WorkingDirectory', $ActionWorkingPath)
        }

        $action = New-ScheduledTaskAction @actionArgs
        
        $settingArgs = @{
            DisallowDemandStart = $DisallowDemandStart           
            DisallowHardTerminate = $DisallowHardTerminate
            Compatibility = $Compatibility
            AllowStartIfOnBatteries = $AllowStartIfOnBatteries
            Disable = -not $Enable
            Hidden = $Hidden
            RunOnlyIfIdle = $RunOnlyIfIdle          
            DisallowStartOnRemoteAppSession = $DisallowStartOnRemoteAppSession            
            StartWhenAvailable = $StartWhenAvailable
            DontStopIfGoingOnBatteries = $DontStopIfGoingOnBatteries
            WakeToRun = $WakeToRun
            RestartOnIdle = $RestartOnIdle
            DontStopOnIdleEnd = $DontStopOnIdleEnd
            MultipleInstances = $MultipleInstances
            Priority = $Priority
            RestartCount = $RestartCount
            RunOnlyIfNetworkAvailable = $RunOnlyIfNetworkAvailable
        }
        
        if ($IdleDuration.TimeOfDay -gt [System.TimeSpan] '00:00:00')
        {
            $settingArgs.Add('IdleDuration', $IdleDuration.TimeOfDay)
        }
        
        if ($IdleWaitTimeout.TimeOfDay -gt [System.TimeSpan] '00:00:00')
        {
            $settingArgs.Add('IdleWaitTimeout', $IdleWaitTimeout.TimeOfDay)
        }

        if ($ExecutionTimeLimit.TimeOfDay -gt [System.TimeSpan] '00:00:00')
        {
            $settingArgs.Add('ExecutionTimeLimit', $ExecutionTimeLimit.TimeOfDay)
        }

        if ($RestartInterval.TimeOfDay -gt [System.TimeSpan] '00:00:00')
        {
            $settingArgs.Add('RestartInterval', $RestartInterval.TimeOfDay)
        }
        
        if (-not [System.String]::IsNullOrWhiteSpace($NetworkName))
        {
            $setting.Add('NetworkName', $NetworkName)
        }
        $setting = New-ScheduledTaskSettingsSet @settingArgs
        
        $triggerArgs = @{}
        if ($RandomDelay.TimeOfDay -gt [System.TimeSpan]::FromSeconds(0))
        {
            $triggerArgs.Add('RandomDelay', $RandomDelay.TimeOfDay)
        }

        switch ($ScheduleType)
        {
            'Once'
            {
                $triggerArgs.Add('Once', $true)
                $triggerArgs.Add('At', $StartTime)
                break
            }
            'Daily'
            {
                $triggerArgs.Add('Daily', $true)
                $triggerArgs.Add('At', $StartTime)
                $triggerArgs.Add('DaysInterval', $DaysInterval)
                break
            }
            'Weekly'
            {
                $triggerArgs.Add('Weekly', $true)
                $triggerArgs.Add('At', $StartTime)
                if ($DaysOfWeek.Count -gt 0)
                {
                    $triggerArgs.Add('DaysOfWeek', $DaysOfWeek)
                }

                if ($WeeksInterval -gt 0)
                {
                    $triggerArgs.Add('WeeksInterval', $WeeksInterval)
                }
                break
            }
            'AtStartup'
            {
                $triggerArgs.Add('AtStartup', $true)
                break
            }
            'AtLogOn'
            {
                $triggerArgs.Add('AtLogOn', $true)
                if (-not [System.String]::IsNullOrWhiteSpace($User))
                {
                    $triggerArgs.Add('User', $User)
                }
                break
            }
        }

        $trigger = New-ScheduledTaskTrigger @triggerArgs -ErrorAction SilentlyContinue
        if (-not $trigger)
        {
            New-InvalidOperationException -Message 'Error creating new scheduled task trigger' -ErrorRecord $_
        }

        # To overcome the issue of not being able to set the task repetition for tasks with a schedule type other than Once
        if ($RepeatInterval.TimeOfDay -gt (New-TimeSpan -Seconds 0) -and $PSVersionTable.PSVersion.Major -gt 4)
        {
            if ($RepetitionDuration.TimeOfDay -le $RepeatInterval.TimeOfDay)
            {
                $exceptionMessage ='Repetition interval is set to {0} but repetition duration is {1}' -f $RepeatInterval.TimeOfDay, $RepetitionDuration.TimeOfDay
                New-InvalidArgumentException -Message $exceptionMessage -ArgumentName RepetitionDuration
            }

            $tempTrigger = New-ScheduledTaskTrigger -Once -At 6:6:6 -RepetitionInterval $RepeatInterval.TimeOfDay -RepetitionDuration $RepetitionDuration.TimeOfDay
            Write-Verbose -Message 'PS V5 Copying values from temporary trigger to property Repetition of $trigger.Repetition'
            
            try 
            {
                $trigger.Repetition = $tempTrigger.Repetition
            }
            catch 
            {
                $triggerRepetitionFailed = $true
            }            
        }

        if ($currentValues.Ensure -eq 'Present') 
        {
            Write-Verbose -Message ('Removing previous scheduled task' -f $TaskName)
            $null = Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
        }
        
        Write-Verbose -Message ('Creating new scheduled task' -f $TaskName)

        $scheduledTask = New-ScheduledTask -Action $action -Trigger $trigger -Settings $setting

        if ($RepeatInterval.TimeOfDay -gt (New-TimeSpan -Seconds 0) -and ($PSVersionTable.PSVersion.Major -eq 4 -or $triggerRepetitionFailed))
        {
            if ($RepetitionDuration.TimeOfDay -le $RepeatInterval.TimeOfDay)
            {
                $exceptionMessage = 'Repetition interval is set to {0} but repetition duration is {1}' -f $RepeatInterval.TimeOfDay, $RepetitionDuration.TimeOfDay
                New-InvalidArgumentException -Message $exceptionMessage -ArgumentName RepetitionDuration
            }

            $tempTrigger = New-ScheduledTaskTrigger -Once -At 6:6:6 -RepetitionInterval $RepeatInterval.TimeOfDay -RepetitionDuration $RepetitionDuration.TimeOfDay
            $tempTask = New-ScheduledTask -Trigger $tempTrigger -Action $action
            Write-Verbose -Message 'PS V4 Copying values from temporary trigger to property Repetition of $trigger.Repetition'
            
            $scheduledTask.Triggers[0].Repetition = $tempTask.Triggers[0].Repetition
        }

        if (-not [System.String]::IsNullOrWhiteSpace($Description))
        {
            $scheduledTask.Description = $Description
        }

        $registerArgs = @{
            TaskName = $TaskName
            TaskPath = $TaskPath
            InputObject = $scheduledTask
        }

        if ($PSBoundParameters.ContainsKey('ExecuteAsCredential') -eq $true) 
        {
            $registerArgs.Add('User', $ExecuteAsCredential.UserName)
            $registerArgs.Add('Password', $ExecuteAsCredential.GetNetworkCredential().Password)
        } 
        else 
        {
            $registerArgs.Add('User', 'NT AUTHORITY\SYSTEM')
        }

        $null = Register-ScheduledTask @registerArgs
    }
    
    if ($Ensure -eq 'Absent') 
    {
        Write-Verbose -Message ('Removing scheduled task' -f $TaskName)
        Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
    }
}

<#
.SYNOPSIS
    Tests if the current resource state matches the desired resource state
.PARAMETER TaskName
    The name of the task
.PARAMETER TaskPath
    The path to the task - defaults to the root directory
.PARAMETER Description
    The task description
.PARAMETER ActionExecutable
    The path to the .exe for this task
.PARAMETER ActionArguments
    The arguments to pass the executable
.PARAMETER ActionWorkingPath
    The working path to specify for the executable
.PARAMETER ScheduleType
    When should the task be executed
.PARAMETER RepeatInterval
    How many units (minutes, hours, days) between each run of this task?
.PARAMETER StartTime
    The time of day this task should start at - defaults to 12:00 AM. Not valid for AtLogon and AtStartup tasks
.PARAMETER Ensure
    Present if the task should exist, Absent if it should be removed
.PARAMETER Enable
    True if the task should be enabled, false if it should be disabled
.PARAMETER ExecuteAsCredential
    The credential this task should execute as. If not specified defaults to running as the local system account
.PARAMETER DaysInterval
    Specifies the interval between the days in the schedule. An interval of 1 produces a daily schedule. An interval of 2 produces an every-other day schedule.
.PARAMETER RandomDelay
    Specifies a random amount of time to delay the start time of the trigger. The delay time is a random time between the time the task triggers and the time that you specify in this setting.
.PARAMETER RepetitionDuration
    Specifies how long the repetition pattern repeats after the task starts.
.PARAMETER DaysOfWeek
    Specifies an array of the days of the week on which Task Scheduler runs the task.
.PARAMETER WeeksInterval
    Specifies the interval between the weeks in the schedule. An interval of 1 produces a weekly schedule. An interval of 2 produces an every-other week schedule.
.PARAMETER User
    Specifies the identifier of the user for a trigger that starts a task when a user logs on.
.PARAMETER DisallowDemandStart
    Indicates whether the task is prohibited to run on demand or not. Defaults to $false
.PARAMETER DisallowHardTerminate
    Indicates whether the task is prohibited to be terminated or not. Defaults to $false
.PARAMETER Compatibility
    The task compatibility level. Defaults to Vista.
.PARAMETER AllowStartIfOnBatteries
    Indicates whether the task should start if the machine is on batteries or not. Defaults to $false
.PARAMETER Hidden
    Indicates that the task is hidden in the Task Scheduler UI.
.PARAMETER RunOnlyIfIdle
    Indicates that Task Scheduler runs the task only when the computer is idle.
.PARAMETER IdleWaitTimeout
    Specifies the amount of time that Task Scheduler waits for an idle condition to occur.
.PARAMETER NetworkName
    Specifies the name of a network profile that Task Scheduler uses to determine if the task can run.
    The Task Scheduler UI uses this setting for display purposes. Specify a network name if you specify the RunOnlyIfNetworkAvailable parameter.
.PARAMETER DisallowStartOnRemoteAppSession
    Indicates that the task does not start if the task is triggered to run in a Remote Applications Integrated Locally (RAIL) session.
.PARAMETER StartWhenAvailable
    Indicates that Task Scheduler can start the task at any time after its scheduled time has passed.
.PARAMETER DontStopIfGoingOnBatteries
    Indicates that the task does not stop if the computer switches to battery power.
.PARAMETER WakeToRun
    Indicates that Task Scheduler wakes the computer before it runs the task.
.PARAMETER IdleDuration
    Specifies the amount of time that the computer must be in an idle state before Task Scheduler runs the task.
.PARAMETER RestartOnIdle
    Indicates that Task Scheduler restarts the task when the computer cycles into an idle condition more than once.
.PARAMETER DontStopOnIdleEnd
    Indicates that Task Scheduler does not terminate the task if the idle condition ends before the task is completed.
.PARAMETER ExecutionTimeLimit
    Specifies the amount of time that Task Scheduler is allowed to complete the task.
.PARAMETER MultipleInstances
    Specifies the policy that defines how Task Scheduler handles multiple instances of the task.
.PARAMETER Priority
    Specifies the priority level of the task. Priority must be an integer from 0 (highest priority) to 10 (lowest priority).
    The default value is 7. Priority levels 7 and 8 are used for background tasks. Priority levels 4, 5, and 6 are used for interactive tasks.
.PARAMETER RestartCount
    Specifies the number of times that Task Scheduler attempts to restart the task.
.PARAMETER RestartInterval
    Specifies the amount of time that Task Scheduler attempts to restart the task.
.PARAMETER RunOnlyIfNetworkAvailable
    Indicates that Task Scheduler runs the task only when a network is available. Task Scheduler uses the NetworkID
    parameter and NetworkName parameter that you specify in this cmdlet to determine if the network is available.
#>
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskName,
        
        [Parameter()]
        [System.String]
        $TaskPath = '\',

        [Parameter()]
        [System.String]
        $Description,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        $ActionExecutable,
        
        [Parameter()]
        [System.String]
        $ActionArguments,
        
        [Parameter()]
        [System.String]
        $ActionWorkingPath,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet('Once', 'Daily', 'Weekly', 'AtStartup', 'AtLogOn')]
        $ScheduleType,
        
        [Parameter()]
        [System.DateTime]
        $RepeatInterval = [System.DateTime] '00:00:00',
        
        [Parameter()]
        [System.DateTime]
        $StartTime = [System.DateTime]::Today,
        
        [Parameter()]
        [System.String]
        [ValidateSet('Present', 'Absent')]
        $Ensure = 'Present',
        
        [Parameter()]
        [System.Boolean]
        $Enable = $true,
        
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ExecuteAsCredential,

        [Parameter()]
        [System.UInt32]
        $DaysInterval = 1,

        [Parameter()]
        [System.DateTime]
        $RandomDelay = [System.DateTime] '00:00:00',

        [Parameter()]
        [System.DateTime]
        $RepetitionDuration = [System.DateTime] '00:00:00',

        [Parameter()]
        [System.String[]]
        $DaysOfWeek,

        [Parameter()]
        [System.UInt32]
        $WeeksInterval = 1,

        [Parameter()]
        [System.String]
        $User,

        [Parameter()]
        [System.Boolean]
        $DisallowDemandStart = $false,

        [Parameter()]
        [System.Boolean]
        $DisallowHardTerminate = $false,

        [Parameter()]
        [ValidateSet('AT', 'V1', 'Vista', 'Win7', 'Win8')]
        [System.String]
        $Compatibility = 'Vista',

        [Parameter()]
        [System.Boolean]
        $AllowStartIfOnBatteries = $false,

        [Parameter()]
        [System.Boolean]
        $Hidden = $false,

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfIdle = $false,

        [Parameter()]
        [System.DateTime]
        $IdleWaitTimeout = [System.DateTime] '02:00:00',

        [Parameter()]
        [System.String]
        $NetworkName,

        [Parameter()]
        [System.Boolean]
        $DisallowStartOnRemoteAppSession = $false,

        [Parameter()]
        [System.Boolean]
        $StartWhenAvailable = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopIfGoingOnBatteries = $false,

        [Parameter()]
        [System.Boolean]
        $WakeToRun = $false,

        [Parameter()]
        [System.DateTime]
        $IdleDuration = [System.DateTime] '01:00:00',

        [Parameter()]
        [System.Boolean]
        $RestartOnIdle = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopOnIdleEnd = $false,

        [Parameter()]
        [System.DateTime]
        $ExecutionTimeLimit = [System.DateTime] '8:00:00',

        [Parameter()]
        [ValidateSet('IgnoreNew', 'Parallel', 'Queue')]
        [System.String]
        $MultipleInstances = 'Queue',

        [Parameter()]
        [System.UInt32]
        $Priority = 7,

        [Parameter()]
        [System.UInt32]
        $RestartCount = 0,

        [Parameter()]
        [System.DateTime]
        $RestartInterval = [System.DateTime] '00:00:00',

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfNetworkAvailable = $false
    )
    
    Write-Verbose -Message ('Testing scheduled task {0}' -f $TaskName)

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message 'Current values retrieved'

    if ($Ensure -eq 'Absent' -and $CurrentValues.Ensure -eq 'Absent')
    {
        return $true
    }

    if ($null -eq $CurrentValues) 
    {
        Write-Verbose -Message 'Current values were null'
        return $false 
    }

    Write-Verbose -Message 'Testing DSC parameter state'
    return Test-DscParameterState -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters
}
