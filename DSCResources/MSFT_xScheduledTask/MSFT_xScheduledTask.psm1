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

Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath 'CommonResourceHelper.psm1')

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
        The time of day this task should start at - defaults to 12:00 AM. Not valid for
        AtLogon and AtStartup tasks

    .PARAMETER Ensure
        Present if the task should exist, Absent if it should be removed

    .PARAMETER Enable
        True if the task should be enabled, false if it should be disabled

    .PARAMETER ExecuteAsCredential
        The credential this task should execute as. If not specified defaults to running
        as the local system account

    .PARAMETER DaysInterval
        Specifies the interval between the days in the schedule. An interval of 1 produces
        a daily schedule. An interval of 2 produces an every-other day schedule.

    .PARAMETER RandomDelay
        Specifies a random amount of time to delay the start time of the trigger. The
        delay time is a random time between the time the task triggers and the time that
        you specify in this setting.

    .PARAMETER RepetitionDuration
        Specifies how long the repetition pattern repeats after the task starts.

    .PARAMETER DaysOfWeek
        Specifies an array of the days of the week on which Task Scheduler runs the task.

    .PARAMETER WeeksInterval
        Specifies the interval between the weeks in the schedule. An interval of 1 produces
        a weekly schedule. An interval of 2 produces an every-other week schedule.

    .PARAMETER User
        Specifies the identifier of the user for a trigger that starts a task when a
        user logs on.

    .PARAMETER DisallowDemandStart
        Indicates whether the task is prohibited to run on demand or not. Defaults
        to $false

    .PARAMETER DisallowHardTerminate
        Indicates whether the task is prohibited to be terminated or not. Defaults
        to $false

    .PARAMETER Compatibility
        The task compatibility level. Defaults to Vista.

    .PARAMETER AllowStartIfOnBatteries
        Indicates whether the task should start if the machine is on batteries or not.
        Defaults to $false

    .PARAMETER Hidden
        Indicates that the task is hidden in the Task Scheduler UI.

    .PARAMETER RunOnlyIfIdle
        Indicates that Task Scheduler runs the task only when the computer is idle.

    .PARAMETER IdleWaitTimeout
        Specifies the amount of time that Task Scheduler waits for an idle condition to occur.

    .PARAMETER NetworkName
        Specifies the name of a network profile that Task Scheduler uses to determine
        if the task can run.
        The Task Scheduler UI uses this setting for display purposes. Specify a network
        name if you specify the RunOnlyIfNetworkAvailable parameter.

    .PARAMETER DisallowStartOnRemoteAppSession
        Indicates that the task does not start if the task is triggered to run in a Remote
        Applications Integrated Locally (RAIL) session.

    .PARAMETER StartWhenAvailable
        Indicates that Task Scheduler can start the task at any time after its scheduled
        time has passed.

    .PARAMETER DontStopIfGoingOnBatteries
        Indicates that the task does not stop if the computer switches to battery power.

    .PARAMETER WakeToRun
        Indicates that Task Scheduler wakes the computer before it runs the task.

    .PARAMETER IdleDuration
        Specifies the amount of time that the computer must be in an idle state before
        Task Scheduler runs the task.

    .PARAMETER RestartOnIdle
        Indicates that Task Scheduler restarts the task when the computer cycles into an
        idle condition more than once.

    .PARAMETER DontStopOnIdleEnd
        Indicates that Task Scheduler does not terminate the task if the idle condition
        ends before the task is completed.

    .PARAMETER ExecutionTimeLimit
        Specifies the amount of time that Task Scheduler is allowed to complete the task.

    .PARAMETER MultipleInstances
        Specifies the policy that defines how Task Scheduler handles multiple instances
        of the task.

    .PARAMETER Priority
        Specifies the priority level of the task. Priority must be an integer from 0 (highest priority)
        to 10 (lowest priority). The default value is 7. Priority levels 7 and 8 are
        used for background tasks. Priority levels 4, 5, and 6 are used for interactive tasks.

    .PARAMETER RestartCount
        Specifies the number of times that Task Scheduler attempts to restart the task.

    .PARAMETER RestartInterval
        Specifies the amount of time that Task Scheduler attempts to restart the task.

    .PARAMETER RunOnlyIfNetworkAvailable
        Indicates that Task Scheduler runs the task only when a network is available. Task
        Scheduler uses the NetworkID parameter and NetworkName parameter that you specify
        in this cmdlet to determine if the network is available.
#>
function Get-TargetResource
{
    [CmdletBinding()]
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
        [System.String]
        $RepeatInterval = '00:00:00',

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
        [System.String]
        $RandomDelay = '00:00:00',

        [Parameter()]
        [System.String]
        $RepetitionDuration = '00:00:00',

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
        [System.String]
        $IdleWaitTimeout = '02:00:00',

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
        [System.String]
        $IdleDuration = '01:00:00',

        [Parameter()]
        [System.Boolean]
        $RestartOnIdle = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopOnIdleEnd = $false,

        [Parameter()]
        [System.String]
        $ExecutionTimeLimit = '08:00:00',

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
        [System.String]
        $RestartInterval = '00:00:00',

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfNetworkAvailable = $false
    )

    $TaskPath = ConvertTo-NormalizedTaskPath -TaskPath $TaskPath

    Write-Verbose -Message ('Retrieving existing task ({0} in {1}).' -f $TaskName, $TaskPath)

    $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue

    if ($null -eq $task)
    {
        Write-Verbose -Message ('No task found. returning empty task {0} with Ensure = "Absent".' -f $Taskname)

        return @{
            TaskName         = $TaskName
            ActionExecutable = $ActionExecutable
            Ensure           = 'Absent'
            ScheduleType     = $ScheduleType
        }
    }
    else
    {
        Write-Verbose -Message ('Task {0} found in {1}. Retrieving settings, first action, first trigger and repetition settings.' -f $TaskName, $TaskPath)

        $action = $task.Actions | Select-Object -First 1
        $trigger = $task.Triggers | Select-Object -First 1
        $settings = $task.Settings
        $returnScheduleType = 'Unknown'

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

        Write-Verbose -Message ('Detected schedule type {0} for first trigger.' -f $returnScheduleType)

        $daysOfWeek = @()

        foreach ($binaryAdductor in 1, 2, 4, 8, 16, 32, 64)
        {
            $day = $trigger.DaysOfWeek -band $binaryAdductor

            if ($day -ne 0)
            {
                $daysOfWeek += [xScheduledTask.DaysOfWeek] $day
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
            TaskName                        = $task.TaskName
            TaskPath                        = $task.TaskPath
            StartTime                       = $startAt
            Ensure                          = 'Present'
            Description                     = $task.Description
            ActionExecutable                = $action.Execute
            ActionArguments                 = $action.Arguments
            ActionWorkingPath               = $action.WorkingDirectory
            ScheduleType                    = $returnScheduleType
            RepeatInterval                  = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $trigger.Repetition.Interval
            ExecuteAsCredential             = $task.Principal.UserId
            Enable                          = $settings.Enabled
            DaysInterval                    = $trigger.DaysInterval
            RandomDelay                     = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $trigger.RandomDelay
            RepetitionDuration              = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $trigger.Repetition.Duration -AllowIndefinitely
            DaysOfWeek                      = $daysOfWeek
            WeeksInterval                   = $trigger.WeeksInterval
            User                            = $task.Principal.UserId
            DisallowDemandStart             = -not $settings.AllowDemandStart
            DisallowHardTerminate           = -not $settings.AllowHardTerminate
            Compatibility                   = $settings.Compatibility
            AllowStartIfOnBatteries         = -not $settings.DisallowStartIfOnBatteries
            Hidden                          = $settings.Hidden
            RunOnlyIfIdle                   = $settings.RunOnlyIfIdle
            IdleWaitTimeout                 = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $settings.IdleSettings.IdleWaitTimeout
            NetworkName                     = $settings.NetworkSettings.Name
            DisallowStartOnRemoteAppSession = $settings.DisallowStartOnRemoteAppSession
            StartWhenAvailable              = $settings.StartWhenAvailable
            DontStopIfGoingOnBatteries      = -not $settings.StopIfGoingOnBatteries
            WakeToRun                       = $settings.WakeToRun
            IdleDuration                    = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $settings.IdleSettings.IdleDuration
            RestartOnIdle                   = $settings.IdleSettings.RestartOnIdle
            DontStopOnIdleEnd               = -not $settings.IdleSettings.StopOnIdleEnd
            ExecutionTimeLimit              = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $settings.ExecutionTimeLimit
            MultipleInstances               = $settings.MultipleInstances
            Priority                        = $settings.Priority
            RestartCount                    = $settings.RestartCount
            RestartInterval                 = ConvertTo-TimeSpanStringFromScheduledTaskString -TimeSpan $settings.RestartInterval
            RunOnlyIfNetworkAvailable       = $settings.RunOnlyIfNetworkAvailable
        }
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
        The time of day this task should start at - defaults to 12:00 AM. Not valid for
        AtLogon and AtStartup tasks

    .PARAMETER Ensure
        Present if the task should exist, Absent if it should be removed

    .PARAMETER Enable
        True if the task should be enabled, false if it should be disabled

    .PARAMETER ExecuteAsCredential
        The credential this task should execute as. If not specified defaults to running
        as the local system account

    .PARAMETER DaysInterval
        Specifies the interval between the days in the schedule. An interval of 1 produces
        a daily schedule. An interval of 2 produces an every-other day schedule.

    .PARAMETER RandomDelay
        Specifies a random amount of time to delay the start time of the trigger. The
        delay time is a random time between the time the task triggers and the time that
        you specify in this setting.

    .PARAMETER RepetitionDuration
        Specifies how long the repetition pattern repeats after the task starts.

    .PARAMETER DaysOfWeek
        Specifies an array of the days of the week on which Task Scheduler runs the task.

    .PARAMETER WeeksInterval
        Specifies the interval between the weeks in the schedule. An interval of 1 produces
        a weekly schedule. An interval of 2 produces an every-other week schedule.

    .PARAMETER User
        Specifies the identifier of the user for a trigger that starts a task when a
        user logs on.

    .PARAMETER DisallowDemandStart
        Indicates whether the task is prohibited to run on demand or not. Defaults
        to $false

    .PARAMETER DisallowHardTerminate
        Indicates whether the task is prohibited to be terminated or not. Defaults
        to $false

    .PARAMETER Compatibility
        The task compatibility level. Defaults to Vista.

    .PARAMETER AllowStartIfOnBatteries
        Indicates whether the task should start if the machine is on batteries or not.
        Defaults to $false

    .PARAMETER Hidden
        Indicates that the task is hidden in the Task Scheduler UI.

    .PARAMETER RunOnlyIfIdle
        Indicates that Task Scheduler runs the task only when the computer is idle.

    .PARAMETER IdleWaitTimeout
        Specifies the amount of time that Task Scheduler waits for an idle condition to occur.

    .PARAMETER NetworkName
        Specifies the name of a network profile that Task Scheduler uses to determine
        if the task can run.
        The Task Scheduler UI uses this setting for display purposes. Specify a network
        name if you specify the RunOnlyIfNetworkAvailable parameter.

    .PARAMETER DisallowStartOnRemoteAppSession
        Indicates that the task does not start if the task is triggered to run in a Remote
        Applications Integrated Locally (RAIL) session.

    .PARAMETER StartWhenAvailable
        Indicates that Task Scheduler can start the task at any time after its scheduled
        time has passed.

    .PARAMETER DontStopIfGoingOnBatteries
        Indicates that the task does not stop if the computer switches to battery power.

    .PARAMETER WakeToRun
        Indicates that Task Scheduler wakes the computer before it runs the task.

    .PARAMETER IdleDuration
        Specifies the amount of time that the computer must be in an idle state before
        Task Scheduler runs the task.

    .PARAMETER RestartOnIdle
        Indicates that Task Scheduler restarts the task when the computer cycles into an
        idle condition more than once.

    .PARAMETER DontStopOnIdleEnd
        Indicates that Task Scheduler does not terminate the task if the idle condition
        ends before the task is completed.

    .PARAMETER ExecutionTimeLimit
        Specifies the amount of time that Task Scheduler is allowed to complete the task.

    .PARAMETER MultipleInstances
        Specifies the policy that defines how Task Scheduler handles multiple instances
        of the task.

    .PARAMETER Priority
        Specifies the priority level of the task. Priority must be an integer from 0 (highest priority)
        to 10 (lowest priority). The default value is 7. Priority levels 7 and 8 are
        used for background tasks. Priority levels 4, 5, and 6 are used for interactive tasks.

    .PARAMETER RestartCount
        Specifies the number of times that Task Scheduler attempts to restart the task.

    .PARAMETER RestartInterval
        Specifies the amount of time that Task Scheduler attempts to restart the task.

    .PARAMETER RunOnlyIfNetworkAvailable
        Indicates that Task Scheduler runs the task only when a network is available. Task
        Scheduler uses the NetworkID parameter and NetworkName parameter that you specify
        in this cmdlet to determine if the network is available.
#>
function Set-TargetResource
{
    [CmdletBinding()]
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
        [System.String]
        $RepeatInterval = '00:00:00',

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
        [System.String]
        $RandomDelay = '00:00:00',

        [Parameter()]
        [System.String]
        $RepetitionDuration = '00:00:00',

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
        [System.String]
        $IdleWaitTimeout = '02:00:00',

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
        [System.String]
        $IdleDuration = '01:00:00',

        [Parameter()]
        [System.Boolean]
        $RestartOnIdle = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopOnIdleEnd = $false,

        [Parameter()]
        [System.String]
        $ExecutionTimeLimit = '08:00:00',

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
        [System.String]
        $RestartInterval = '00:00:00',

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfNetworkAvailable = $false
    )

    $TaskPath = ConvertTo-NormalizedTaskPath -TaskPath $TaskPath

    Write-Verbose -Message ('Entering Set-TargetResource for {0} in {1}.' -f $TaskName, $TaskPath)

    # Convert the strings containing time spans to TimeSpan Objects
    [System.TimeSpan] $RepeatInterval = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RepeatInterval
    [System.TimeSpan] $RandomDelay = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RandomDelay
    [System.TimeSpan] $RepetitionDuration = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RepetitionDuration -AllowIndefinitely
    [System.TimeSpan] $IdleWaitTimeout = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $IdleWaitTimeout
    [System.TimeSpan] $IdleDuration = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $IdleDuration
    [System.TimeSpan] $ExecutionTimeLimit = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $ExecutionTimeLimit
    [System.TimeSpan] $RestartInterval = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RestartInterval

    $currentValues = Get-TargetResource @PSBoundParameters

    if ($Ensure -eq 'Present')
    {
        if ($RepetitionDuration -lt $RepeatInterval)
        {
            $exceptionMessage = 'Repetition duration {0} is less than repetition interval {1}. Please set RepeatInterval to a value lower or equal to RepetitionDuration.' -f $RepetitionDuration, $RepeatInterval
            New-InvalidArgumentException -Message $exceptionMessage -ArgumentName RepeatInterval
        }

        if ($ScheduleType -eq 'Daily' -and $DaysInterval -eq 0)
        {
            $exceptionMessage = 'Schedules of the type Daily must have a DaysInterval greater than 0 (value entered: {0}).' -f $DaysInterval
            New-InvalidArgumentException -Message $exceptionMessage -ArgumentName DaysInterval
        }

        if ($ScheduleType -eq 'Weekly' -and $WeeksInterval -eq 0)
        {
            $exceptionMessage = 'Schedules of the type Weekly must have a WeeksInterval greater than 0 (value entered: {0}).' -f $WeeksInterval
            New-InvalidArgumentException -Message $exceptionMessage -ArgumentName WeeksInterval
        }

        if ($ScheduleType -eq 'Weekly' -and $DaysOfWeek.Count -eq 0)
        {
            $exceptionMessage = 'Schedules of the type Weekly must have at least one weekday selected.'
            New-InvalidArgumentException -Message $exceptionMessage -ArgumentName DaysOfWeek
        }

        $actionParameters = @{
            Execute = $ActionExecutable
        }

        if ($ActionArguments)
        {
            $actionParameters.Add('Argument', $ActionArguments)
        }

        if ($ActionWorkingPath)
        {
            $actionParameters.Add('WorkingDirectory', $ActionWorkingPath)
        }

        $action = New-ScheduledTaskAction @actionParameters

        $settingParameters = @{
            DisallowDemandStart             = $DisallowDemandStart
            DisallowHardTerminate           = $DisallowHardTerminate
            Compatibility                   = $Compatibility
            AllowStartIfOnBatteries         = $AllowStartIfOnBatteries
            Disable                         = -not $Enable
            Hidden                          = $Hidden
            RunOnlyIfIdle                   = $RunOnlyIfIdle
            DisallowStartOnRemoteAppSession = $DisallowStartOnRemoteAppSession
            StartWhenAvailable              = $StartWhenAvailable
            DontStopIfGoingOnBatteries      = $DontStopIfGoingOnBatteries
            WakeToRun                       = $WakeToRun
            RestartOnIdle                   = $RestartOnIdle
            DontStopOnIdleEnd               = $DontStopOnIdleEnd
            MultipleInstances               = $MultipleInstances
            Priority                        = $Priority
            RestartCount                    = $RestartCount
            RunOnlyIfNetworkAvailable       = $RunOnlyIfNetworkAvailable
        }

        if ($IdleDuration -gt [System.TimeSpan] '00:00:00')
        {
            $settingParameters.Add('IdleDuration', $IdleDuration)
        }

        if ($IdleWaitTimeout -gt [System.TimeSpan] '00:00:00')
        {
            $settingParameters.Add('IdleWaitTimeout', $IdleWaitTimeout)
        }

        if ($ExecutionTimeLimit -gt [System.TimeSpan] '00:00:00')
        {
            $settingParameters.Add('ExecutionTimeLimit', $ExecutionTimeLimit)
        }

        if ($RestartInterval -gt [System.TimeSpan] '00:00:00')
        {
            $settingParameters.Add('RestartInterval', $RestartInterval)
        }

        if (-not [System.String]::IsNullOrWhiteSpace($NetworkName))
        {
            $settingParameters.Add('NetworkName', $NetworkName)
        }

        $setting = New-ScheduledTaskSettingsSet @settingParameters

        $triggerParameters = @{}

        if ($RandomDelay -gt [System.TimeSpan]::FromSeconds(0))
        {
            $triggerParameters.Add('RandomDelay', $RandomDelay)
        }

        switch ($ScheduleType)
        {
            'Once'
            {
                $triggerParameters.Add('Once', $true)
                $triggerParameters.Add('At', $StartTime)
                break
            }

            'Daily'
            {
                $triggerParameters.Add('Daily', $true)
                $triggerParameters.Add('At', $StartTime)
                $triggerParameters.Add('DaysInterval', $DaysInterval)
                break
            }

            'Weekly'
            {
                $triggerParameters.Add('Weekly', $true)
                $triggerParameters.Add('At', $StartTime)
                if ($DaysOfWeek.Count -gt 0)
                {
                    $triggerParameters.Add('DaysOfWeek', $DaysOfWeek)
                }

                if ($WeeksInterval -gt 0)
                {
                    $triggerParameters.Add('WeeksInterval', $WeeksInterval)
                }
                break
            }

            'AtStartup'
            {
                $triggerParameters.Add('AtStartup', $true)
                break
            }

            'AtLogOn'
            {
                $triggerParameters.Add('AtLogOn', $true)
                if (-not [System.String]::IsNullOrWhiteSpace($User))
                {
                    $triggerParameters.Add('User', $User)
                }
                break
            }
        }

        $trigger = New-ScheduledTaskTrigger @triggerParameters -ErrorAction SilentlyContinue

        if (-not $trigger)
        {
            $exceptionMessage = 'Error creating new scheduled task trigger.'
            New-InvalidOperationException -Message $exceptionMessage -ErrorRecord $_
        }

        if ($RepeatInterval -gt [System.TimeSpan]::Parse('0:0:0'))
        {
            # A repetition pattern is required so create it and attach it to the trigger object
            Write-Verbose -Message ('Configuring trigger repetition.')

            if ($RepetitionDuration -le $RepeatInterval)
            {
                $exceptionMessage = 'Repetition interval is set to {0} but repetition duration is {1}.' -f $RepeatInterval, $RepetitionDuration
                New-InvalidArgumentException -Message $exceptionMessage -ArgumentName RepetitionDuration
            }

            $tempTriggerParameters = @{
                Once               = $true
                At                 = '6:6:6'
                RepetitionInterval = $RepeatInterval
            }

            Write-Verbose -Message ('Creating MSFT_TaskRepetitionPattern CIM instance to configure repetition in trigger.')

            switch ($trigger.GetType().FullName)
            {
                'Microsoft.PowerShell.ScheduledJob.ScheduledJobTrigger'
                {
                    # This is the type of trigger object returned in Windows Server 2012 R2/Windows 8.1 and below
                    Write-Verbose -Message ('Creating temporary task and trigger to get MSFT_TaskRepetitionPattern CIM instance.')

                    $tempTriggerParameters.Add('RepetitionDuration', $RepetitionDuration)

                    # Create a temporary trigger and task and copy the repetition CIM object from the temporary task
                    $tempTrigger = New-ScheduledTaskTrigger @tempTriggerParameters
                    $tempTask = New-ScheduledTask -Action $action -Trigger $tempTrigger

                    # Store the repetition settings
                    $repetition = $tempTask.Triggers[0].Repetition
                }

                'Microsoft.Management.Infrastructure.CimInstance'
                {
                    # This is the type of trigger object returned in Windows Server 2016/Windows 10 and above
                    Write-Verbose -Message ('Creating temporary trigger to get MSFT_TaskRepetitionPattern CIM instance.')

                    if ($RepetitionDuration -gt [System.TimeSpan]::Parse('0:0:0') -and $RepetitionDuration -lt [System.TimeSpan]::MaxValue)
                    {
                        $tempTriggerParameters.Add('RepetitionDuration', $RepetitionDuration)
                    }

                    # Create a temporary trigger and copy the repetition CIM object from it to the actual trigger
                    $tempTrigger = New-ScheduledTaskTrigger @tempTriggerParameters

                    # Store the repetition settings
                    $repetition = $tempTrigger.Repetition
                }

                default
                {
                    New-InvalidOperationException `
                        -Message ('Trigger object that was created was of unexpected type {0}.' -f $trigger.GetType().FullName)
                }
            }
        }

        if ($currentValues.Ensure -eq 'Present')
        {
            Write-Verbose -Message ('Removing previous scheduled task {0}.' -f $TaskName)
            $null = Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
        }

        Write-Verbose -Message ('Creating new scheduled task {0}.' -f $TaskName)

        $scheduledTask = New-ScheduledTask -Action $action -Trigger $trigger -Settings $setting

        if ($repetition)
        {
            Write-Verbose -Message ('Setting repetition trigger settings on task {0}.' -f $TaskName)
            $scheduledTask.Triggers[0].Repetition = $repetition
        }

        if (-not [System.String]::IsNullOrWhiteSpace($Description))
        {
            $scheduledTask.Description = $Description
        }

        $registerArguments = @{
            TaskName    = $TaskName
            TaskPath    = $TaskPath
            InputObject = $scheduledTask
        }

        if ($PSBoundParameters.ContainsKey('ExecuteAsCredential') -eq $true)
        {
            $registerArguments.Add('User', $ExecuteAsCredential.UserName)
            $registerArguments.Add('Password', $ExecuteAsCredential.GetNetworkCredential().Password)
        }
        else
        {
            $registerArguments.Add('User', 'NT AUTHORITY\SYSTEM')
        }

        Write-Verbose -Message ('Registering the scheduled task {0}.' -f $TaskName)

        $null = Register-ScheduledTask @registerArguments
    }

    if ($Ensure -eq 'Absent')
    {
        Write-Verbose -Message ('Removing the scheduled task {0}.' -f $TaskName)

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
        The time of day this task should start at - defaults to 12:00 AM. Not valid for
        AtLogon and AtStartup tasks

    .PARAMETER Ensure
        Present if the task should exist, Absent if it should be removed

    .PARAMETER Enable
        True if the task should be enabled, false if it should be disabled

    .PARAMETER ExecuteAsCredential
        The credential this task should execute as. If not specified defaults to running
        as the local system account

    .PARAMETER DaysInterval
        Specifies the interval between the days in the schedule. An interval of 1 produces
        a daily schedule. An interval of 2 produces an every-other day schedule.

    .PARAMETER RandomDelay
        Specifies a random amount of time to delay the start time of the trigger. The
        delay time is a random time between the time the task triggers and the time that
        you specify in this setting.

    .PARAMETER RepetitionDuration
        Specifies how long the repetition pattern repeats after the task starts.

    .PARAMETER DaysOfWeek
        Specifies an array of the days of the week on which Task Scheduler runs the task.

    .PARAMETER WeeksInterval
        Specifies the interval between the weeks in the schedule. An interval of 1 produces
        a weekly schedule. An interval of 2 produces an every-other week schedule.

    .PARAMETER User
        Specifies the identifier of the user for a trigger that starts a task when a
        user logs on.

    .PARAMETER DisallowDemandStart
        Indicates whether the task is prohibited to run on demand or not. Defaults
        to $false

    .PARAMETER DisallowHardTerminate
        Indicates whether the task is prohibited to be terminated or not. Defaults
        to $false

    .PARAMETER Compatibility
        The task compatibility level. Defaults to Vista.

    .PARAMETER AllowStartIfOnBatteries
        Indicates whether the task should start if the machine is on batteries or not.
        Defaults to $false

    .PARAMETER Hidden
        Indicates that the task is hidden in the Task Scheduler UI.

    .PARAMETER RunOnlyIfIdle
        Indicates that Task Scheduler runs the task only when the computer is idle.

    .PARAMETER IdleWaitTimeout
        Specifies the amount of time that Task Scheduler waits for an idle condition to occur.

    .PARAMETER NetworkName
        Specifies the name of a network profile that Task Scheduler uses to determine
        if the task can run.
        The Task Scheduler UI uses this setting for display purposes. Specify a network
        name if you specify the RunOnlyIfNetworkAvailable parameter.

    .PARAMETER DisallowStartOnRemoteAppSession
        Indicates that the task does not start if the task is triggered to run in a Remote
        Applications Integrated Locally (RAIL) session.

    .PARAMETER StartWhenAvailable
        Indicates that Task Scheduler can start the task at any time after its scheduled
        time has passed.

    .PARAMETER DontStopIfGoingOnBatteries
        Indicates that the task does not stop if the computer switches to battery power.

    .PARAMETER WakeToRun
        Indicates that Task Scheduler wakes the computer before it runs the task.

    .PARAMETER IdleDuration
        Specifies the amount of time that the computer must be in an idle state before
        Task Scheduler runs the task.

    .PARAMETER RestartOnIdle
        Indicates that Task Scheduler restarts the task when the computer cycles into an
        idle condition more than once.

    .PARAMETER DontStopOnIdleEnd
        Indicates that Task Scheduler does not terminate the task if the idle condition
        ends before the task is completed.

    .PARAMETER ExecutionTimeLimit
        Specifies the amount of time that Task Scheduler is allowed to complete the task.

    .PARAMETER MultipleInstances
        Specifies the policy that defines how Task Scheduler handles multiple instances
        of the task.

    .PARAMETER Priority
        Specifies the priority level of the task. Priority must be an integer from 0 (highest priority)
        to 10 (lowest priority). The default value is 7. Priority levels 7 and 8 are
        used for background tasks. Priority levels 4, 5, and 6 are used for interactive tasks.

    .PARAMETER RestartCount
        Specifies the number of times that Task Scheduler attempts to restart the task.

    .PARAMETER RestartInterval
        Specifies the amount of time that Task Scheduler attempts to restart the task.

    .PARAMETER RunOnlyIfNetworkAvailable
        Indicates that Task Scheduler runs the task only when a network is available. Task
        Scheduler uses the NetworkID parameter and NetworkName parameter that you specify
        in this cmdlet to determine if the network is available.
#>
function Test-TargetResource
{
    [CmdletBinding()]
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
        [System.String]
        $RepeatInterval = '00:00:00',

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
        [System.String]
        $RandomDelay = '00:00:00',

        [Parameter()]
        [System.String]
        $RepetitionDuration = '00:00:00',

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
        [System.String]
        $IdleWaitTimeout = '02:00:00',

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
        [System.String]
        $IdleDuration = '01:00:00',

        [Parameter()]
        [System.Boolean]
        $RestartOnIdle = $false,

        [Parameter()]
        [System.Boolean]
        $DontStopOnIdleEnd = $false,

        [Parameter()]
        [System.String]
        $ExecutionTimeLimit = '08:00:00',

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
        [System.String]
        $RestartInterval = '00:00:00',

        [Parameter()]
        [System.Boolean]
        $RunOnlyIfNetworkAvailable = $false
    )

    $TaskPath = ConvertTo-NormalizedTaskPath -TaskPath $TaskPath

    # Convert the strings containing time spans to TimeSpan Objects
    if ($PSBoundParameters.ContainsKey('RepeatInterval'))
    {
        $PSBoundParameters['RepeatInterval'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RepeatInterval).ToString()
    }

    if ($PSBoundParameters.ContainsKey('RandomDelay'))
    {
        $PSBoundParameters['RandomDelay'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RandomDelay).ToString()
    }

    if ($PSBoundParameters.ContainsKey('RepetitionDuration'))
    {
        $RepetitionDuration = ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RepetitionDuration -AllowIndefinitely
        if ($RepetitionDuration -eq [System.TimeSpan]::MaxValue)
        {
            $PSBoundParameters['RepetitionDuration'] = 'Indefinitely'
        }
        else
        {
            $PSBoundParameters['RepetitionDuration'] = $RepetitionDuration.ToString()
        }

    }

    if ($PSBoundParameters.ContainsKey('IdleWaitTimeout'))
    {
        $PSBoundParameters['IdleWaitTimeout'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $IdleWaitTimeout).ToString()
    }

    if ($PSBoundParameters.ContainsKey('IdleDuration'))
    {
        $PSBoundParameters['IdleDuration'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $IdleDuration).ToString()
    }

    if ($PSBoundParameters.ContainsKey('ExecutionTimeLimit'))
    {
        $PSBoundParameters['ExecutionTimeLimit'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $ExecutionTimeLimit).ToString()
    }

    if ($PSBoundParameters.ContainsKey('RestartInterval'))
    {
        $PSBoundParameters['RestartInterval'] = (ConvertTo-TimeSpanFromTimeSpanString -TimeSpanString $RestartInterval).ToString()
    }

    Write-Verbose -Message ('Testing scheduled task {0}' -f $TaskName)

    $currentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message 'Current values retrieved'

    if ($Ensure -eq 'Absent' -and $currentValues.Ensure -eq 'Absent')
    {
        return $true
    }

    if ($null -eq $currentValues)
    {
        Write-Verbose -Message 'Current values were null.'
        return $false
    }

    $desiredValues = $PSBoundParameters
    $desiredValues.TaskPath = $TaskPath
    Write-Verbose -Message 'Testing DSC parameter state.'
    return Test-DscParameterState -CurrentValues $currentValues -DesiredValues $desiredValues
}

<#
    .SYNOPSIS
        Helper function to convert TaskPath to the right form

    .PARAMETER TaskPath
        The path to the task
#>
function ConvertTo-NormalizedTaskPath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskPath
    )

    $pathArray = $TaskPath.Split('\').Where( {$_})
    if ($pathArray.Count -gt 0)
    {
        $TaskPath = "\$($pathArray -join '\')\"
    }

    return $TaskPath
}

<#
    .SYNOPSIS
        Helper function convert a standard timespan string
        into a TimeSpan object. It can support returning the
        maximum timespan if the AllowIndefinitely switch is set
        and the timespan is set to 'indefinte'.

    .PARAMETER TimeSpan
        The standard timespan string to convert to a TimeSpan
        object.

    .PARAMETER AllowIndefinitely
        Allow the keyword 'Indefinitely' to be translated into
        the maximum valid timespan.
#>
function ConvertTo-TimeSpanFromTimeSpanString
{
    [CmdletBinding()]
    [OutputType([System.TimeSpan])]
    param
    (
        [Parameter()]
        [System.String]
        $TimeSpanString = '00:00:00',

        [Parameter()]
        [Switch]
        $AllowIndefinitely
    )

    if ($AllowIndefinitely -eq $True -and $TimeSpanString -eq 'Indefinitely')
    {
        return [System.TimeSpan]::MaxValue
    }

    return [System.TimeSpan]::Parse($TimeSpanString)
}

<#
    .SYNOPSIS
        Helper function convert a task schedule timespan string
        into a TimeSpan string. If AllowIndefinitely is set to
        true and the TimeSpan string is empty then return
        'Indefinitely'.

    .PARAMETER TimeSpan
        The scheduled task timespan string to convert to a TimeSpan
        string.

    .PARAMETER AllowIndefinitely
        Allow an empty TimeSpan to return the keyword 'Indefinitely'.

#>
function ConvertTo-TimeSpanStringFromScheduledTaskString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $TimeSpan,

        [Parameter()]
        [Switch]
        $AllowIndefinitely
    )

    # If AllowIndefinitely is true and the timespan is empty then return Indefinitely
    if ($AllowIndefinitely -eq $true -and [String]::IsNullOrEmpty($TimeSpan))
    {
        return 'Indefinitely'
    }

    $days = $hours = $minutes = $seconds = 0

    if ($TimeSpan -match 'P(?<Days>\d{0,3})D')
    {
        $days = $matches.Days
    }

    if ($TimeSpan -match '(?<Hours>\d{0,2})H')
    {
        $hours = $matches.Hours
    }

    if ($TimeSpan -match '(?<Minutes>\d{0,2})M')
    {
        $minutes = $matches.Minutes
    }

    if ($TimeSpan -match '(?<Seconds>\d{0,2})S')
    {
        $seconds = $matches.Seconds
    }

    return (New-TimeSpan -Days $days -Hours $hours -Minutes $minutes -Seconds $seconds).ToString()
}
