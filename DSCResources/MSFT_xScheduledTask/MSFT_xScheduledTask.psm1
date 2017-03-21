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

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskName,
        
        [System.String]
        $TaskPath = "\",

        [System.String]
        $Description,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        $ActionExecutable,
        
        [System.String]
        $ActionArguments,
        
        [System.String]
        $ActionWorkingPath,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Once", "Daily", "Weekly", "AtStartup", "AtLogOn")]
        $ScheduleType,
        
        [System.DateTime]
        $RepeatInterval = [datetime]"00:00:00",
        
        [System.DateTime]
        $StartTime = [datetime]::Today,
        
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure = "Present",
        
        [System.Boolean]
        $Enable = $true,
        
        [System.Management.Automation.PSCredential]
        $ExecuteAsCredential,

        [System.UInt32]
        $DaysInterval = 1,

        [System.DateTime]
        $RandomDelay = [datetime]"00:00:00",

        [System.DateTime]
        $RepetitionDuration = [datetime]"00:00:00",

        [System.String[]]
        $DaysOfWeek,

        [System.UInt32]
        $WeeksInterval = 1,

        [System.String]
        $User,

        [System.Boolean]
        $DisallowDemandStart = $false,

        [System.Boolean]
        $DisallowHardTerminate = $false,

        [ValidateSet("AT", "V1", "Vista", "Win7", "Win8")]
        [System.String]
        $Compatibility = "Vista",

        [System.Boolean]
        $AllowStartIfOnBatteries = $false,

        [System.Boolean]
        $Hidden = $false,

        [System.Boolean]
        $RunOnlyIfIdle = $false,

        [System.DateTime]
        $IdleWaitTimeout = [datetime]"02:00:00",

        [System.String]
        $NetworkName,

        [System.Boolean]
        $DisallowStartOnRemoteAppSession = $false,

        [System.Boolean]
        $StartWhenAvailable = $false,

        [System.Boolean]
        $DontStopIfGoingOnBatteries = $false,

        [System.Boolean]
        $WakeToRun = $false,

        [System.DateTime]
        $IdleDuration = [datetime]"01:00:00",

        [System.Boolean]
        $RestartOnIdle = $false,

        [System.Boolean]
        $DontStopOnIdleEnd = $false,

        [System.DateTime]
        $ExecutionTimeLimit = [datetime]"8:00:00",

        [ValidateSet("IgnoreNew", "Parallel", "Queue")]
        [System.String]
        $MultipleInstances = "Queue",

        [System.UInt32]
        $Priority = 7,

        [System.UInt32]
        $RestartCount = 0,

        [System.DateTime]
        $RestartInterval = [datetime]"00:00:00",

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
            Ensure = "Absent"
            ScheduleType = $ScheduleType
        }
    } 
    else 
    {
        Write-Verbose -Message ('Task {0} found in {1}. Retrieving settings, first action, first trigger and repetition settings' -f $TaskName, $TaskPath)
        $action = $task.Actions | Select-Object -First 1
        $trigger = $task.Triggers | Select-Object -First 1
        $settings = $task.Settings
        $returnScheduleType = "Unknown"
        $returnInveral = 0

        switch ($trigger.CimClass.CimClassName)
        {
            "MSFT_TaskTimeTrigger"
            {
                $returnScheduleType = "Once"
                break;
            }
            "MSFT_TaskDailyTrigger"
            {
                $returnScheduleType = "Daily"
                break;
            }
            
            "MSFT_TaskWeeklyTrigger"
            {
                $returnScheduleType = "Weekly"
                break;
            }
            
            "MSFT_TaskBootTrigger"
            {
                $returnScheduleType = "AtStartup"
                break;
            }
            
            "MSFT_TaskLogonTrigger"
            {
                $returnScheduleType = "AtLogon"
                break;
            }

            default
            {
                throw "Trigger type $_ not recognized."
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
                $DaysOfWeek += [xScheduledTask.DaysOfWeek]$Day
            }
        }

        $startAt = $trigger.StartBoundary

        if ($startAt)
        {
            $startAt = [datetime]$startAt
        }
        else
        {
            $startAt = $StartTime
        }
        
        return @{
            TaskName = $TaskName
            TaskPath = $TaskPath
            StartTime = $startAt
            Ensure = "Present"
            Description = $task.Description
            ActionExecutable = $action.Execute
            ActionArguments = $action.Arguments
            ActionWorkingPath = $action.WorkingDirectory
            ScheduleType = $returnScheduleType
            RepeatInterval = [datetime]::Today.Add($returnInveral)
            ExecuteAsCredential = $task.Principal.UserId
            Enable = $settings.Enabled
            DaysInterval = $trigger.DaysInterval
            RandomDelay = [datetime]::Today.Add($randomDelayReturn)
            RepetitionDuration = [datetime]::Today.Add($repetitionDurationReturn)
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
            IdleDuration = [datetime]::Today.Add($idleDurationReturn)
            RestartOnIdle = $settings.IdleSettings.RestartOnIdle
            DontStopOnIdleEnd = -not $settings.IdleSettings.StopOnIdleEnd
            ExecutionTimeLimit = [datetime]::Today.Add($executionTimeLimitReturn)
            MultipleInstances = $settings.MultipleInstances
            Priority = $settings.Priority
            RestartCount = $settings.RestartCount
            RestartInterval = [datetime]::Today.Add($restartIntervalReturn)
            RunOnlyIfNetworkAvailable = $settings.RunOnlyIfNetworkAvailable
        }
    }
}

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskName,
        
        [System.String]
        $TaskPath = "\",

        [System.String]
        $Description,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        $ActionExecutable,
        
        [System.String]
        $ActionArguments,
        
        [System.String]
        $ActionWorkingPath,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Once", "Daily", "Weekly", "AtStartup", "AtLogOn")]
        $ScheduleType,
        
        [System.DateTime]
        $RepeatInterval = [datetime]"00:00:00",
        
        [System.DateTime]
        $StartTime = [datetime]::Today,
        
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure = "Present",
        
        [System.Boolean]
        $Enable = $true,
        
        [System.Management.Automation.PSCredential]
        $ExecuteAsCredential,

        [System.UInt32]
        $DaysInterval,

        [System.DateTime]
        $RandomDelay = [datetime]"00:00:00",

        [System.DateTime]
        $RepetitionDuration = [datetime]"00:00:00",

        [System.String[]]
        $DaysOfWeek,

        [System.UInt32]
        $WeeksInterval,

        [System.String]
        $User,

        [System.Boolean]
        $DisallowDemandStart = $false,

        [System.Boolean]
        $DisallowHardTerminate = $false,

        [ValidateSet("AT", "V1", "Vista", "Win7", "Win8")]
        [System.String]
        $Compatibility = "Vista",

        [System.Boolean]
        $AllowStartIfOnBatteries = $false,

        [System.Boolean]
        $Hidden = $false,

        [System.Boolean]
        $RunOnlyIfIdle = $false,

        [System.DateTime]
        $IdleWaitTimeout = [datetime]"02:00:00",

        [System.String]
        $NetworkName,

        [System.Boolean]
        $DisallowStartOnRemoteAppSession = $false,

        [System.Boolean]
        $StartWhenAvailable = $false,

        [System.Boolean]
        $DontStopIfGoingOnBatteries = $false,

        [System.Boolean]
        $WakeToRun = $false,

        [System.DateTime]
        $IdleDuration = [datetime]"01:00:00",

        [System.Boolean]
        $RestartOnIdle = $false,

        [System.Boolean]
        $DontStopOnIdleEnd = $false,

        [System.DateTime]
        $ExecutionTimeLimit = [datetime]"8:00:00",

        [ValidateSet("IgnoreNew", "Parallel", "Queue")]
        [System.String]
        $MultipleInstances = "Queue",

        [System.UInt32]
        $Priority = 7,

        [System.UInt32]
        $RestartCount,

        [System.DateTime]
        $RestartInterval = [datetime]"00:00:00",

        [System.Boolean]
        $RunOnlyIfNetworkAvailable = $false
    )
    
    Write-Verbose -Message ('Entering Set-TargetResource for {0} in {1}' -f $TaskName,$TaskPath)
    $currentValues = Get-TargetResource @PSBoundParameters
    
    if ($Ensure -eq "Present") 
    {
        if ($RepetitionDuration.TimeOfDay -lt $RepeatInterval.TimeOfDay)
        {
            $exceptionObject = New-Object -TypeName System.ArgumentException -ArgumentList `
                    ('Repetition duration {0} is less than repetition interval {1}. Please set RepeatInterval to a value lower or equal to RepetitionDuration' -f $RepetitionDuration.TimeOfDay,$RepeatInterval.TimeOfDay),`
                    'RepeatInterval'
                throw $exceptionObject
        }

        if ($ScheduleType -eq 'Daily' -and $DaysInterval -eq 0)
        {
            $exceptionObject = New-Object -TypeName System.ArgumentException -ArgumentList `
                    ('Schedules of the type Daily must have a DaysInterval greater than 0 (value entered: {0})' -f $DaysInterval),`
                    'DaysInterval'
                throw $exceptionObject
        }

        if ($ScheduleType -eq 'Weekly' -and $WeeksInterval -eq 0)
        {
            $exceptionObject = New-Object -TypeName System.ArgumentException -ArgumentList `
                    ('Schedules of the type Weekly must have a WeeksInterval greater than 0 (value entered: {0})' -f $WeeksInterval),`
                    'WeeksInterval'
                throw $exceptionObject
        }

        if ($ScheduleType -eq 'Weekly' -and $DaysOfWeek.Count -eq 0)
        {
            $exceptionObject = New-Object -TypeName System.ArgumentException -ArgumentList `
                    'Schedules of the type Weekly must have at least one weekday selected', 'DaysOfWeek'
                throw $exceptionObject
        }

        $actionArgs = @{
            Execute = $ActionExecutable
        }

        if ($ActionArguments) 
        { 
            $actionArgs.Add("Argument", $ActionArguments)
        }

        if ($ActionWorkingPath) 
        { 
            $actionArgs.Add("WorkingDirectory", $ActionWorkingPath)
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
        
        if ($IdleDuration.TimeOfDay -gt [timespan]"00:00:00")
        {
            $settingArgs.Add('IdleDuration', $IdleDuration.TimeOfDay)
        }
        
        if ($IdleWaitTimeout.TimeOfDay -gt [timespan]"00:00:00")
        {
            $settingArgs.Add('IdleWaitTimeout', $IdleWaitTimeout.TimeOfDay)
        }

        if ($ExecutionTimeLimit.TimeOfDay -gt [timespan]"00:00:00")
        {
            $settingArgs.Add('ExecutionTimeLimit', $ExecutionTimeLimit.TimeOfDay)
        }

        if ($RestartInterval.TimeOfDay -gt [timespan]"00:00:00")
        {
            $settingArgs.Add('RestartInterval', $RestartInterval.TimeOfDay)
        }
        
        if (-not [string]::IsNullOrWhiteSpace($NetworkName))
        {
            $setting.Add('NetworkName', $NetworkName)
        }
        $setting = New-ScheduledTaskSettingsSet @settingArgs
        
        $triggerArgs = @{}
        if ($RandomDelay.TimeOfDay -gt [timespan]::FromSeconds(0))
        {
            $triggerArgs.Add('RandomDelay', $RandomDelay.TimeOfDay)
        }

        switch ($ScheduleType)
        {
            "Once"
            {
                $triggerArgs.Add('Once', $true)
                $triggerArgs.Add('At', $StartTime)
                break;
            }
            "Daily"
            {
                $triggerArgs.Add('Daily', $true)
                $triggerArgs.Add('At', $StartTime)
                $triggerArgs.Add('DaysInterval', $DaysInterval)
                break;
            }
            "Weekly"
            {
                $triggerArgs.Add('Weekly', $true)
                $triggerArgs.Add('At', $StartTime)
                if ($DaysOfWeek.Count -gt 0)
                {
                    $triggerArgs.Add('DaysOfWeek', $DaysOfWeek)
                }

                if($WeeksInterval -gt 0)
                {
                    $triggerArgs.Add('WeeksInterval', $WeeksInterval)
                }
                break;
            }
            "AtStartup"
            {
                $triggerArgs.Add('AtStartup', $true)
                break;
            }
            "AtLogOn"
            {
                $triggerArgs.Add('AtLogOn', $true)
                if (-not [string]::IsNullOrWhiteSpace($User))
                {
                    $triggerArgs.Add('User', $User)
                }
                break;
            }
        }

        $trigger = New-ScheduledTaskTrigger @triggerArgs -ErrorAction SilentlyContinue
        if(-not $trigger)
        {
            throw "Error creating new scheduled task trigger. $($_.Exception.Message)"
        }

        # To overcome the issue of not being able to set the task repetition for tasks with a schedule type other than Once
        if ($RepeatInterval.TimeOfDay -gt (New-TimeSpan -Seconds 0) -and $PSVersionTable.PSVersion.Major -gt 4)
        {
            if ($RepetitionDuration.TimeOfDay -le $RepeatInterval.TimeOfDay)
            {
                $exceptionObject = New-Object System.ArgumentException -ArgumentList `
                    ('Repetition interval is set to {0} but repetition duration is {1}' -f $RepeatInterval.TimeOfDay, $RepetitionDuration.TimeOfDay),`
                    'RepetitionDuration'
                throw $exceptionObject
            }

            $tempTrigger = New-ScheduledTaskTrigger -Once -At 6:6:6 -RepetitionInterval $RepeatInterval.TimeOfDay -RepetitionDuration $RepetitionDuration.TimeOfDay
            Write-Verbose -Message 'PS V5 Copying values from temporary trigger to property Repetition of $trigger.Repetition'
            
            $trigger.Repetition = $tempTrigger.Repetition
        }

        if ($currentValues.Ensure -eq "Present") 
        {
            Write-Verbose -Message ('Removing previous scheduled task' -f $TaskName)
            $null = Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
        }
        
        Write-Verbose -Message ('Creating new scheduled task' -f $TaskName)

        $scheduledTask = New-ScheduledTask -Action $action -Trigger $trigger -Settings $setting

        if ($RepeatInterval.TimeOfDay -gt (New-TimeSpan -Seconds 0) -and $PSVersionTable.PSVersion.Major -eq 4)
        {
            if ($RepetitionDuration.TimeOfDay -le $RepeatInterval.TimeOfDay)
            {
                $exceptionObject = New-Object System.ArgumentException -ArgumentList `
                    ('Repetition interval is set to {0} but repetition duration is {1}' -f $RepeatInterval.TimeOfDay, $RepetitionDuration.TimeOfDay),`
                    'RepetitionDuration'
                throw $exceptionObject
            }

            $tempTrigger = New-ScheduledTaskTrigger -Once -At 6:6:6 -RepetitionInterval $RepeatInterval.TimeOfDay -RepetitionDuration $RepetitionDuration.TimeOfDay
            $tempTask = New-ScheduledTask -Trigger $tempTrigger -Action $action
            Write-Verbose -Message 'PS V4 Copying values from temporary trigger to property Repetition of $trigger.Repetition'
            
            $scheduledTask.Triggers[0].Repetition = $tempTask.Triggers[0].Repetition
        }

        if (-not [string]::IsNullOrWhiteSpace($Description))
        {
            $scheduledTask.Description = $Description
        }

        $registerArgs = @{
            TaskName = $TaskName
            TaskPath = $TaskPath
            InputObject = $scheduledTask
        }

        if ($PSBoundParameters.ContainsKey("ExecuteAsCredential") -eq $true) 
        {
            $registerArgs.Add("User", $ExecuteAsCredential.UserName)
            $registerArgs.Add("Password", $ExecuteAsCredential.GetNetworkCredential().Password)
        } 
        else 
        {
            $registerArgs.Add("User", "NT AUTHORITY\SYSTEM")
        }

        $null = Register-ScheduledTask @registerArgs
    }
    
    if ($Ensure -eq "Absent") 
    {
        Write-Verbose -Message ('Removing scheduled task' -f $TaskName)
        Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
    }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TaskName,
        
        [System.String]
        $TaskPath = "\",

        [System.String]
        $Description,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        $ActionExecutable,
        
        [System.String]
        $ActionArguments,
        
        [System.String]
        $ActionWorkingPath,
        
        [Parameter(Mandatory = $true)]
        [System.String]
        [ValidateSet("Once", "Daily", "Weekly", "AtStartup", "AtLogOn")]
        $ScheduleType,
        
        [System.DateTime]
        $RepeatInterval = [datetime]"00:00:00",
        
        [System.DateTime]
        $StartTime = [datetime]::Today,
        
        [System.String]
        [ValidateSet("Present", "Absent")]
        $Ensure = "Present",
        
        [System.Boolean]
        $Enable = $true,
        
        [System.Management.Automation.PSCredential]
        $ExecuteAsCredential,

        [System.UInt32]
        $DaysInterval = 1,

        [System.DateTime]
        $RandomDelay = [datetime]"00:00:00",

        [System.DateTime]
        $RepetitionDuration = [datetime]"00:00:00",

        [System.String[]]
        $DaysOfWeek,

        [System.UInt32]
        $WeeksInterval = 1,

        [System.String]
        $User,

        [System.Boolean]
        $DisallowDemandStart = $false,

        [System.Boolean]
        $DisallowHardTerminate = $false,

        [ValidateSet("AT", "V1", "Vista", "Win7", "Win8")]
        [System.String]
        $Compatibility = "Vista",

        [System.Boolean]
        $AllowStartIfOnBatteries = $false,

        [System.Boolean]
        $Hidden = $false,

        [System.Boolean]
        $RunOnlyIfIdle = $false,

        [System.DateTime]
        $IdleWaitTimeout = [datetime]"02:00:00",

        [System.String]
        $NetworkName,

        [System.Boolean]
        $DisallowStartOnRemoteAppSession = $false,

        [System.Boolean]
        $StartWhenAvailable = $false,

        [System.Boolean]
        $DontStopIfGoingOnBatteries = $false,

        [System.Boolean]
        $WakeToRun = $false,

        [System.DateTime]
        $IdleDuration = [datetime]"01:00:00",

        [System.Boolean]
        $RestartOnIdle = $false,

        [System.Boolean]
        $DontStopOnIdleEnd = $false,

        [System.DateTime]
        $ExecutionTimeLimit = [datetime]"8:00:00",

        [ValidateSet("IgnoreNew", "Parallel", "Queue")]
        [System.String]
        $MultipleInstances = "Queue",

        [System.UInt32]
        $Priority = 7,

        [System.UInt32]
        $RestartCount = 0,

        [System.DateTime]
        $RestartInterval = [datetime]"00:00:00",

        [System.Boolean]
        $RunOnlyIfNetworkAvailable = $false
    )
    
    Write-Verbose -Message ('Testing scheduled task {0}' -f $TaskName)

    $CurrentValues = Get-TargetResource @PSBoundParameters

    Write-Verbose -Message "Current values retrieved"

    if ($Ensure -eq 'Absent' -and $CurrentValues.Ensure -eq 'Absent')
    {
        return $true
    }

    if ($null -eq $CurrentValues) 
    {
        Write-Verbose -Message "Current values were null"
        return $false 
    }

    Write-Verbose "Testing DSC parameter state"
    return Test-DscParameterState -CurrentValues $CurrentValues -DesiredValues $PSBoundParameters
}
