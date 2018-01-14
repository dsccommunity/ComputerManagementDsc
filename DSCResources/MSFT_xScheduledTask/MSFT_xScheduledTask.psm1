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

$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import the ComputerManagementDsc Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.ResourceHelper' `
            -ChildPath 'ComputerManagementDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xScheduledTask' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        Tests if the current resource state matches the desired resource state.

    .PARAMETER TaskName
        The name of the task.

    .PARAMETER TaskPath
        The path to the task - defaults to the root directory.

    .PARAMETER Description
        The task description. Not used in Get-TargetResource.

    .PARAMETER ActionExecutable
        The path to the .exe for this task.

    .PARAMETER ActionArguments
        The arguments to pass the executable. Not used in Get-TargetResource.

    .PARAMETER ActionWorkingPath
        The working path to specify for the executable. Not used in Get-TargetResource.

    .PARAMETER ScheduleType
        When should the task be executed.

    .PARAMETER RepeatInterval
        How many units (minutes, hours, days) between each run of this task?
        Not used in Get-TargetResource.

    .PARAMETER StartTime
        The time of day this task should start at - defaults to 12:00 AM. Not valid for
        AtLogon and AtStartup tasks. Not used in Get-TargetResource.

    .PARAMETER Ensure
        Present if the task should exist, Absent if it should be removed.

    .PARAMETER Enable
        True if the task should be enabled, false if it should be disabled.
        Not used in Get-TargetResource.

    .PARAMETER ExecuteAsCredential
        The credential this task should execute as. If not specified defaults to running
        as the local system account.
        Not used in Get-TargetResource.

    .PARAMETER DaysInterval
        Specifies the interval between the days in the schedule. An interval of 1 produces
        a daily schedule. An interval of 2 produces an every-other day schedule.
        Not used in Get-TargetResource.

    .PARAMETER RandomDelay
        Specifies a random amount of time to delay the start time of the trigger. The
        delay time is a random time between the time the task triggers and the time that
        you specify in this setting. Not used in Get-TargetResource.

    .PARAMETER RepetitionDuration
        Specifies how long the repetition pattern repeats after the task starts.
        Not used in Get-TargetResource.

    .PARAMETER DaysOfWeek
        Specifies an array of the days of the week on which Task Scheduler runs the task.
        Not used in Get-TargetResource.

    .PARAMETER WeeksInterval
        Specifies the interval between the weeks in the schedule. An interval of 1 produces
        a weekly schedule. An interval of 2 produces an every-other week schedule.
        Not used in Get-TargetResource.

    .PARAMETER User
        Specifies the identifier of the user for a trigger that starts a task when a
        user logs on. Not used in Get-TargetResource.

    .PARAMETER DisallowDemandStart
        Indicates whether the task is prohibited to run on demand or not. Defaults
        to $false. Not used in Get-TargetResource.

    .PARAMETER DisallowHardTerminate
        Indicates whether the task is prohibited to be terminated or not. Defaults
        to $false

    .PARAMETER Compatibility
        The task compatibility level. Defaults to Vista. Not used in
        Get-TargetResource.

    .PARAMETER AllowStartIfOnBatteries
        Indicates whether the task should start if the machine is on batteries or not.
        Defaults to $false. Not used in Get-TargetResource.

    .PARAMETER Hidden
        Indicates that the task is hidden in the Task Scheduler UI.
        Not used in Get-TargetResource.

    .PARAMETER RunOnlyIfIdle
        Indicates that Task Scheduler runs the task only when the computer is idle.
        Not used in Get-TargetResource.

    .PARAMETER IdleWaitTimeout
        Specifies the amount of time that Task Scheduler waits for an idle condition to occur.
        Not used in Get-TargetResource.

    .PARAMETER NetworkName
        Specifies the name of a network profile that Task Scheduler uses to determine
        if the task can run.
        The Task Scheduler UI uses this setting for display purposes. Specify a network
        name if you specify the RunOnlyIfNetworkAvailable parameter. Not used in
        Get-TargetResource.

    .PARAMETER DisallowStartOnRemoteAppSession
        Indicates that the task does not start if the task is triggered to run in a Remote
        Applications Integrated Locally (RAIL) session. Not used in Get-TargetResource.

    .PARAMETER StartWhenAvailable
        Indicates that Task Scheduler can start the task at any time after its scheduled
        time has passed. Not used in Get-TargetResource.

    .PARAMETER DontStopIfGoingOnBatteries
        Indicates that the task does not stop if the computer switches to battery power.
        Not used in Get-TargetResource.

    .PARAMETER WakeToRun
        Indicates that Task Scheduler wakes the computer before it runs the task.
        Not used in Get-TargetResource.

    .PARAMETER IdleDuration
        Specifies the amount of time that the computer must be in an idle state before
        Task Scheduler runs the task. Not used in Get-TargetResource.

    .PARAMETER RestartOnIdle
        Indicates that Task Scheduler restarts the task when the computer cycles into an
        idle condition more than once. Not used in Get-TargetResource.

    .PARAMETER DontStopOnIdleEnd
        Indicates that Task Scheduler does not terminate the task if the idle condition
        ends before the task is completed. Not used in Get-TargetResource.

    .PARAMETER ExecutionTimeLimit
        Specifies the amount of time that Task Scheduler is allowed to complete the task.
        Not used in Get-TargetResource.

    .PARAMETER MultipleInstances
        Specifies the policy that defines how Task Scheduler handles multiple instances
        of the task. Not used in Get-TargetResource.

    .PARAMETER Priority
        Specifies the priority level of the task. Priority must be an integer from 0 (highest priority)
        to 10 (lowest priority). The default value is 7. Priority levels 7 and 8 are
        used for background tasks. Priority levels 4, 5, and 6 are used for interactive tasks.
        Not used in Get-TargetResource.

    .PARAMETER RestartCount
        Specifies the number of times that Task Scheduler attempts to restart the task.
        Not used in Get-TargetResource.

    .PARAMETER RestartInterval
        Specifies the amount of time that Task Scheduler attempts to restart the task.
        Not used in Get-TargetResource.

    .PARAMETER RunOnlyIfNetworkAvailable
        Indicates that Task Scheduler runs the task only when a network is available. Task
        Scheduler uses the NetworkID parameter and NetworkName parameter that you specify
        in this cmdlet to determine if the network is available. Not used in Get-TargetResource.

    .PARAMETER RunLevel
        Specifies the level of user rights that Task Scheduler uses to run the tasks that
        are associated with the principal. Defaults to 'Limited'. Not used in
        Get-TargetResource.

    .PARAMETER LogonType
        Specifies the security logon method that Task Scheduler uses to run the tasks that
        are associated with the principal. Not used in Get-TargetResource.
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

        [Parameter()]
        [System.String]
        $ActionExecutable,

        [Parameter()]
        [System.String]
        $ActionArguments,

        [Parameter()]
        [System.String]
        $ActionWorkingPath,

        [Parameter()]
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
        $RunOnlyIfNetworkAvailable = $false,

        [Parameter()]
        [ValidateSet('Limited', 'Highest')]
        [System.String]
        $RunLevel = 'Limited',

        [Parameter()]
        [ValidateSet('Group', 'Interactive', 'InteractiveOrPassword', 'None', 'Password', 'S4U', 'ServiceAccount')]
        [System.String]
        $LogonType
    )

    $TaskPath = ConvertTo-NormalizedTaskPath -TaskPath $TaskPath

    Write-Verbose -Message ($script:localizedData.GetScheduledTaskMessage -f $TaskName, $TaskPath)

    $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue

    if ($null -eq $task)
    {
        Write-Verbose -Message ($script:localizedData.TaskNotFoundMessage -f $TaskName, $TaskPath)

        return @{
            TaskName = $TaskName
            TaskPath = $TaskPath
            Ensure   = 'Absent'
        }
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.TaskFoundMessage -f $TaskName, $TaskPath)

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
                New-InvalidArgumentException `
                    -Message ($script:localizedData.TriggerTypeError -f $trigger.CimClass.CimClassName) `
                    -ArgumentName CimClassName
            }
        }

        Write-Verbose -Message ($script:localizedData.DetectedScheduleTypeMessage -f $returnScheduleType)

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
            RunLevel                        = [System.String] $task.Principal.RunLevel
            LogonType                       = [System.String] $task.Principal.LogonType
        }
    }
}

<#
    .SYNOPSIS
        Tests if the current resource state matches the desired resource state.

    .PARAMETER TaskName
        The name of the task.

    .PARAMETER TaskPath
        The path to the task - defaults to the root directory.

    .PARAMETER Description
        The task description.

    .PARAMETER ActionExecutable
        The path to the .exe for this task.

    .PARAMETER ActionArguments
        The arguments to pass the executable.

    .PARAMETER ActionWorkingPath
        The working path to specify for the executable.

    .PARAMETER ScheduleType
        When should the task be executed.

    .PARAMETER RepeatInterval
        How many units (minutes, hours, days) between each run of this task?

    .PARAMETER StartTime
        The time of day this task should start at - defaults to 12:00 AM. Not valid for
        AtLogon and AtStartup tasks.

    .PARAMETER Ensure
        Present if the task should exist, Absent if it should be removed.

    .PARAMETER Enable
        True if the task should be enabled, false if it should be disabled.

    .PARAMETER ExecuteAsCredential
        The credential this task should execute as. If not specified defaults to running
        as the local system account.

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
        to $false.

    .PARAMETER DisallowHardTerminate
        Indicates whether the task is prohibited to be terminated or not. Defaults
        to $false.

    .PARAMETER Compatibility
        The task compatibility level. Defaults to Vista.

    .PARAMETER AllowStartIfOnBatteries
        Indicates whether the task should start if the machine is on batteries or not.
        Defaults to $false.

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
        in this cmdlet to determine if the network is available.\

    .PARAMETER RunLevel
        Specifies the level of user rights that Task Scheduler uses to run the tasks that
        are associated with the principal. Defaults to 'Limited'.

    .PARAMETER LogonType
        Specifies the security logon method that Task Scheduler uses to run the tasks that
        are associated with the principal.
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

        [Parameter()]
        [System.String]
        $ActionExecutable,

        [Parameter()]
        [System.String]
        $ActionArguments,

        [Parameter()]
        [System.String]
        $ActionWorkingPath,

        [Parameter()]
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
        $RunOnlyIfNetworkAvailable = $false,

        [Parameter()]
        [ValidateSet('Limited', 'Highest')]
        [System.String]
        $RunLevel = 'Limited',

        [Parameter()]
        [ValidateSet('Group', 'Interactive', 'InteractiveOrPassword', 'None', 'Password', 'S4U', 'ServiceAccount')]
        [System.String]
        $LogonType
    )

    $TaskPath = ConvertTo-NormalizedTaskPath -TaskPath $TaskPath

    Write-Verbose -Message ($script:localizedData.SetScheduledTaskMessage -f $TaskName, $TaskPath)

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
        <#
            If the scheduled task already exists and is enabled but it needs to be disabled
            and the action executable isn't specified then disable the task
        #>
        if ($currentValues.Ensure -eq 'Present' `
            -and $currentValues.Enable `
            -and -not $Enable `
            -and -not $PSBoundParameters.ContainsKey('ActionExecutable'))
        {
            Write-Verbose -Message ($script:localizedData.DisablingExistingScheduledTask -f $TaskName, $TaskPath)
            Disable-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath

            return
        }

        if ($RepetitionDuration -lt $RepeatInterval)
        {
            New-InvalidArgumentException `
                -Message ($script:localizedData.RepetitionDurationLessThanIntervalError -f $RepetitionDuration, $RepeatInterval) `
                -ArgumentName RepeatInterval
        }

        if ($ScheduleType -eq 'Daily' -and $DaysInterval -eq 0)
        {
            New-InvalidArgumentException `
                -Message ($script:localizedData.DaysIntervalError -f $DaysInterval) `
                -ArgumentName DaysInterval
        }

        if ($ScheduleType -eq 'Weekly' -and $WeeksInterval -eq 0)
        {
            New-InvalidArgumentException `
                -Message ($script:localizedData.WeeksIntervalError -f $WeeksInterval) `
                -ArgumentName WeeksInterval
        }

        if ($ScheduleType -eq 'Weekly' -and $DaysOfWeek.Count -eq 0)
        {
            New-InvalidArgumentException `
                -Message ($script:localizedData.WeekDayMissingError) `
                -ArgumentName DaysOfWeek
        }

        # Configure the action
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

        $scheduledTaskArguments += @{
            Action = $action
        }

        # Configure the settings
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

        if ($PSBoundParameters.ContainsKey('ExecutionTimeLimit'))
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

        $scheduledTaskArguments += @{
            Settings = $setting
        }

        <#
            On Windows Server 2012 R2 setting a blank timespan for ExecutionTimeLimit
            does not result in the PT0S timespan value being set. So set this
            if it has not been set.
        #>
        if ($PSBoundParameters.ContainsKey('ExecutionTimeLimit') -and `
                [System.String]::IsNullOrEmpty($setting.ExecutionTimeLimit))
        {
            $setting.ExecutionTimeLimit = 'PT0S'
        }

        # Configure the trigger
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
            New-InvalidOperationException `
                -Message ($script:localizedData.TriggerCreationError) `
                -ErrorRecord $_
        }

        if ($RepeatInterval -gt [System.TimeSpan]::Parse('0:0:0'))
        {
            # A repetition pattern is required so create it and attach it to the trigger object
            Write-Verbose -Message ($script:localizedData.ConfigureTriggerRepetitionMessage)

            if ($RepetitionDuration -le $RepeatInterval)
            {
                New-InvalidArgumentException `
                    -Message ($script:localizedData.RepetitionIntervalError -f $RepeatInterval, $RepetitionDuration) `
                    -ArgumentName RepetitionDuration
            }

            $tempTriggerParameters = @{
                Once               = $true
                At                 = '6:6:6'
                RepetitionInterval = $RepeatInterval
            }

            Write-Verbose -Message ($script:localizedData.CreateRepetitionPatternMessage)

            switch ($trigger.GetType().FullName)
            {
                'Microsoft.PowerShell.ScheduledJob.ScheduledJobTrigger'
                {
                    # This is the type of trigger object returned in Windows Server 2012 R2/Windows 8.1 and below
                    Write-Verbose -Message ($script:localizedData.CreateTemporaryTaskMessage)

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
                    Write-Verbose -Message ($script:localizedData.CreateTemporaryTriggerMessage)

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
                        -Message ($script:localizedData.TriggerUnexpectedTypeError -f $trigger.GetType().FullName)
                }
            }
        }

        $scheduledTaskArguments += @{
            Trigger = $trigger
        }

        # Prepare the register arguments
        $registerArguments = @{
            TaskName = $TaskName
            TaskPath = $TaskPath
        }

        if ($PSBoundParameters.ContainsKey('ExecuteAsCredential'))
        {
            $username = $ExecuteAsCredential.UserName
            $registerArguments.Add('User', $username)

            # If the LogonType is not specified then set it to password
            if ([System.String]::IsNullOrEmpty($LogonType))
            {
                $LogonType = 'Password'
            }

            if ($LogonType -notin ('Interactive', 'S4U'))
            {
                # Only set the password if the LogonType is not interactive or S4U
                $registerArguments.Add('Password', $ExecuteAsCredential.GetNetworkCredential().Password)
            }
        }
        else
        {
            $username = 'NT AUTHORITY\SYSTEM'
            $registerArguments.Add('User', $username)
            $LogonType = 'ServiceAccount'
        }

        # Prepare the principal arguments
        $principalArguments = @{
            Id        = 'Author'
            UserId    = $username
            LogonType = $LogonType
        }

        # Set the Run Level if defined
        if ($PSBoundParameters.ContainsKey('RunLevel'))
        {
            $principalArguments.Add('RunLevel', $RunLevel)
        }

        # Create the principal object
        Write-Verbose -Message ($script:localizedData.CreateScheduledTaskPrincipalMessage -f $username, $LogonType)

        $principal = New-ScheduledTaskPrincipal @principalArguments

        $scheduledTaskArguments += @{
            Principal = $principal
        }

        if ($currentValues.Ensure -eq 'Present')
        {
            Write-Verbose -Message ($script:localizedData.RemovePreviousScheduledTaskMessage -f $TaskName, $TaskPath)

            $null = Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false -ErrorAction Stop
        }

        Write-Verbose -Message ($script:localizedData.CreateNewScheduledTaskMessage -f $TaskName, $TaskPath)

        # Create the scheduled task object
        $scheduledTask = New-ScheduledTask @scheduledTaskArguments -ErrorAction Stop

        if ($repetition)
        {
            Write-Verbose -Message ($script:localizedData.SetRepetitionTriggerMessage -f $TaskName, $TaskPath)

            $scheduledTask.Triggers[0].Repetition = $repetition
        }

        if (-not [System.String]::IsNullOrWhiteSpace($Description))
        {
            $scheduledTask.Description = $Description
        }

        # Register the scheduled task
        $registerArguments.Add('InputObject', $scheduledTask)

        Write-Verbose -Message ($script:localizedData.RegisterScheduledTaskMessage -f $TaskName, $TaskPath)

        $null = Register-ScheduledTask @registerArguments -ErrorAction Stop
    }

    if ($Ensure -eq 'Absent')
    {
        Write-Verbose -Message ($script:localizedData.RemoveScheduledTaskMessage -f $TaskName, $TaskPath)

        Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false -ErrorAction Stop
    }
}

<#
    .SYNOPSIS
        Tests if the current resource state matches the desired resource state.

    .PARAMETER TaskName
        The name of the task.

    .PARAMETER TaskPath
        The path to the task - defaults to the root directory.

    .PARAMETER Description
        The task description.

    .PARAMETER ActionExecutable
        The path to the .exe for this task.

    .PARAMETER ActionArguments
        The arguments to pass the executable.

    .PARAMETER ActionWorkingPath
        The working path to specify for the executable.

    .PARAMETER ScheduleType
        When should the task be executed.

    .PARAMETER RepeatInterval
        How many units (minutes, hours, days) between each run of this task?

    .PARAMETER StartTime
        The time of day this task should start at - defaults to 12:00 AM. Not valid for
        AtLogon and AtStartup tasks.

    .PARAMETER Ensure
        Present if the task should exist, Absent if it should be removed.

    .PARAMETER Enable
        True if the task should be enabled, false if it should be disabled.

    .PARAMETER ExecuteAsCredential
        The credential this task should execute as. If not specified defaults to running
        as the local system account.

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
        to $false.

    .PARAMETER DisallowHardTerminate
        Indicates whether the task is prohibited to be terminated or not. Defaults
        to $false.

    .PARAMETER Compatibility
        The task compatibility level. Defaults to Vista.

    .PARAMETER AllowStartIfOnBatteries
        Indicates whether the task should start if the machine is on batteries or not.
        Defaults to $false.

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

    .PARAMETER RunLevel
        Specifies the level of user rights that Task Scheduler uses to run the tasks that
        are associated with the principal. Defaults to 'Limited'.

    .PARAMETER LogonType
        Specifies the security logon method that Task Scheduler uses to run the tasks that
        are associated with the principal.
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

        [Parameter()]
        [System.String]
        $ActionExecutable,

        [Parameter()]
        [System.String]
        $ActionArguments,

        [Parameter()]
        [System.String]
        $ActionWorkingPath,

        [Parameter()]
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
        $RunOnlyIfNetworkAvailable = $false,

        [Parameter()]
        [ValidateSet('Limited', 'Highest')]
        [System.String]
        $RunLevel = 'Limited',

        [Parameter()]
        [ValidateSet('Group', 'Interactive', 'InteractiveOrPassword', 'None', 'Password', 'S4U', 'ServiceAccount')]
        [System.String]
        $LogonType
    )

    $TaskPath = ConvertTo-NormalizedTaskPath -TaskPath $TaskPath

    Write-Verbose -Message ($script:localizedData.TestScheduledTaskMessage -f $TaskName, $TaskPath)

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

    $currentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message ($script:localizedData.GetCurrentTaskValuesMessage)

    if ($Ensure -eq 'Absent' -and $currentValues.Ensure -eq 'Absent')
    {
        return $true
    }

    if ($null -eq $currentValues)
    {
        Write-Verbose -Message ($script:localizedData.CurrentTaskValuesNullMessage)

        return $false
    }

    if ($PSBoundParameters.ContainsKey('ExecuteAsCredential'))
    {
        # The password of the execution credential can not be compared
        $username = $ExecuteAsCredential.UserName
        $PSBoundParameters['ExecuteAsCredential'] = $username
    }

    $desiredValues = $PSBoundParameters
    $desiredValues.TaskPath = $TaskPath

    Write-Verbose -Message ($script:localizedData.TestingDscParameterStateMessage)

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
    if ($AllowIndefinitely -eq $true -and [System.String]::IsNullOrEmpty($TimeSpan))
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

<#
    .SYNOPSIS
        Helper function to disable an existing scheduled task.

    .PARAMETER TaskName
        The name of the task to disable.

    .PARAMETER TaskPath
        The path to the task to disable.
#>
function Disable-ScheduledTask
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskName,

        [Parameter()]
        [System.String]
        $TaskPath = '\'
    )

    $existingTask = Get-ScheduledTask @PSBoundParameters
    $existingTask.Settings.Enabled = $false
    $null = $existingTask | Register-ScheduledTask @PSBoundParameters -Force
}
