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

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory=$true)]
        [System.String]
        $TaskName,
        
        [System.String]
        $TaskPath = "\",

        [System.String]
        $Description,
        
        [Parameter(Mandatory=$true)]
        [System.String]
        $ActionExecutable,
        
        [System.String]
        $ActionArguments,
        
        [System.String]
        $ActionWorkingPath,
        
        [Parameter(Mandatory=$true)]
        [System.String]
        [ValidateSet("Once", "Daily", "Weekly", "AtStartup", "AtLogOn")]
        $ScheduleType,
        
        [System.DateTime]
        $RepeatInterval = [datetime]"00:00:00",
        
        [System.DateTime]
        $StartTime = [datetime]::Today,
        
        [System.String]
        [ValidateSet("Present","Absent")]
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

        [ValidateSet("AT","V1","Vista","Win7","Win8")]
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

        [ValidateSet("IgnoreNew","Parallel","Queue")]
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

    $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
    
    if ($null -eq $task) 
    {
        return @{
            TaskName = $TaskName
            TaskPath = $TaskPath
            Ensure = "Absent"
            TriggerType = "Unknown"
        }
    } 
    else 
    {
        $action = $task.Actions | Select-Object -First 1
        $trigger = $task.Triggers | Select-Object -First 1
        $settings = $task.Settings
        $repetition = $trigger.Repetition
        $returnScheduleType = "Unknown"
        $returnInveral = 0

        switch($trigger.CimClass.CimClassName)
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
        foreach($binaryAdductor in 1,2,4,8,16,32,64)
        {
            $Day = $trigger.DaysOfWeek -band $binaryAdductor
            if($Day -ne 0)
            {
                $DaysOfWeek += [xScheduledTask.DaysOfWeek]$Day
            }
        }
        
        return @{
            TaskName = $TaskName
            TaskPath = $TaskPath
            Ensure = "Present"
            ActionExecutable  = $action.Execute
            ActionArguments   = $action.Arguments
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
            User = $trigger.UserId
            DisallowDemandStart = $settings.DisallowDemandStart
            DisallowHardTerminate = $settings.DisallowHardTerminate
            Compatibility = $settings.Compatibility
            AllowStartIfOnBatteries = $settings.AllowStartIfOnBatteries
            Hidden = $settings.Hidden
            RunOnlyIfIdle = $settings.RunOnlyIfIdle
            IdleWaitTimeout = $idleWaitTimeout
            NetworkName = $settings.NetworkSettings.Name
            DisallowStartOnRemoteAppSession = $settings.DisallowStartOnRemoteAppSession
            StartWhenAvailable = $settings.StartWhenAvailable
            DontStopIfGoingOnBatteries = $settings.DontStopIfGoingOnBatteries
            WakeToRun = $settings.WakeToRun
            IdleDuration = [datetime]::Today.Add($idleDurationReturn)
            RestartOnIdle = $settings.IdleSettings.RestartOnIdle
            DontStopOnIdleEnd = -not $settings.IdleSettings.StopOnIdleEnd
            ExecutionTimeLimit = [datetime]::Today.Add($executionTimeLimitReturn)
            MultipleInstances = [System.String]
            Priority = [System.UInt32]
            RestartCount = [System.UInt32]
            RestartInterval = [System.DateTime]
            RunOnlyIfNetworkAvailable = $settings.RunOnlyIfNetworkAvailable
        }
    }
}

function Set-TargetResource
{
    param
    (
        [Parameter(Mandatory=$true)]
        [System.String]
        $TaskName,
        
        [System.String]
        $TaskPath = "\",

        [System.String]
        $Description,
        
        [Parameter(Mandatory=$true)]
        [System.String]
        $ActionExecutable,
        
        [System.String]
        $ActionArguments,
        
        [System.String]
        $ActionWorkingPath,
        
        [Parameter(Mandatory=$true)]
        [System.String]
        [ValidateSet("Once", "Daily", "Weekly", "AtStartup", "AtLogOn")]
        $ScheduleType,
        
        [System.DateTime]
        $RepeatInterval = [datetime]"00:00:00",
        
        [System.DateTime]
        $StartTime = [datetime]::Today,
        
        [System.String]
        [ValidateSet("Present","Absent")]
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

        [ValidateSet("AT","V1","Vista","Win7","Win8")]
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

        [ValidateSet("IgnoreNew","Parallel","Queue")]
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
    
    $currentValues = Get-TargetResource @PSBoundParameters
    
    if ($Ensure -eq "Present") 
    {
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
            Disable = $Disable
            Hidden = $Hidden
            RunOnlyIfIdle = $RunOnlyIfIdle          
            DisallowStartOnRemoteAppSession = $DisallowStartOnRemoteAppSession            
            StartWhenAvailable  = $StartWhenAvailable
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
        
        if(-not [string]::IsNullOrWhiteSpace($NetworkName))
        {
            $setting.Add('NetworkName', $NetworkName)
        }
        $setting = New-ScheduledTaskSettingsSet @settingArgs
        
        $triggerArgs = @{}
        if ($RandomDelay.TimeOfDay -gt [timespan]::FromSeconds(0))
        {
            $triggerArgs.Add('RandomDelay', $RandomDelay)
        }

        switch ($ScheduleType)
        {
            "Once"
            {
                $triggerArgs.Add('Once',$true)
                $triggerArgs.Add('At', $StartTime.TimeOfDay)

                break;
            }
            "Daily"
            {
                $triggerArgs.Add('Daily',$true)
                $triggerArgs.Add('At', $StartTime.TimeOfDay)
                $triggerArgs.Add('DaysInterval', $DaysInterval)
                break;
            }
            "Weekly"
            {
                $triggerArgs.Add('Weekly',$true)
                $triggerArgs.Add('At', $StartTime.TimeOfDay)
                if ($DaysOfWeek.Count -gt 0)
                {
                    $triggerArgs.Add('DaysOfWeek', $DaysOfWeek)
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
                if  (-not [string]::IsNullOrWhiteSpace($User))
                {
                    $triggerArgs.Add('User', $User)
                }
                break;
            }
        }

        $trigger = New-ScheduledTaskTrigger @triggerArgs
        
        if ($currentValues.Ensure -eq "Absent") 
        {
            Write-Verbose -Message "Creating new scheduled task `"$TaskName`""

            $scheduledTask = New-ScheduledTask -Action $action -Trigger $trigger -Settings $setting
            if  (-not [string]::IsNullOrWhiteSpace($Description))
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

            Register-ScheduledTask @registerArgs
        }
        if ($currentValues.Ensure -eq "Present") 
        {
            Write-Verbose -Message "Updating scheduled task `"$TaskName`""
            
            $setArgs = @{
                TaskName = $TaskName
                TaskPath = $TaskPath
                Action= $action
                Trigger = $trigger
                Settings = $setting
            }

            if ($PSBoundParameters.ContainsKey("ExecuteAsCredential") -eq $true) 
            {
                $setArgs.Add("User", $ExecuteAsCredential.UserName)
                $setArgs.Add("Password", $ExecuteAsCredential.GetNetworkCredential().Password)
            } 
            else 
            {
                $setArgs.Add("User", "NT AUTHORITY\SYSTEM")
            }

            Set-ScheduledTask @setArgs
        }
    }
    
    if ($Ensure -eq "Absent") 
    {
        Write-Verbose -Message "Removing scheduled task `"$TaskName`""
        Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Confirm:$false
    }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory=$true)]
        [System.String]
        $TaskName,
        
        [System.String]
        $TaskPath = "\",

        [System.String]
        $Description,
        
        [Parameter(Mandatory=$true)]
        [System.String]
        $ActionExecutable,
        
        [System.String]
        $ActionArguments,
        
        [System.String]
        $ActionWorkingPath,
        
        [Parameter(Mandatory=$true)]
        [System.String]
        [ValidateSet("Once", "Daily", "Weekly", "AtStartup", "AtLogOn")]
        $ScheduleType,
        
        [System.DateTime]
        $RepeatInterval = [datetime]"00:00:00",
        
        [System.DateTime]
        $StartTime = [datetime]::Today,
        
        [System.String]
        [ValidateSet("Present","Absent")]
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

        [ValidateSet("AT","V1","Vista","Win7","Win8")]
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

        [ValidateSet("IgnoreNew","Parallel","Queue")]
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
    
    $currentValues = Get-TargetResource @PSBoundParameters
    if ($Ensure -ne $currentValues.Ensure) 
    { 
        return $false 
    }
    if ($Ensure -eq "Present") 
    {
        if ($TaskPath -ne $currentValues.TaskPath) 
        { 
            Write-Verbose -Message "TaskPath does not match desired state. Current value: $($currentValues.TaskPath) - Desired Value: $TaskPath"
            return $false 
        }
        if ($ActionExecutable -ne $currentValues.ActionExecutable) 
        { 
            Write-Verbose -Message "ActionExecutable does not match desired state. Current value: $($currentValues.ActionExecutable) - Desired Value: $ActionExecutable"
            return $false 
        }
        if (($PSBoundParameters.ContainsKey("ActionArguments") -eq $true) `
            -and ($ActionArguments -ne $currentValues.ActionArguments)) 
        { 
            Write-Verbose -Message "ActionArguments does not match desired state. Current value: $($currentValues.ActionArguments) - Desired Value: $ActionArguments"
            return $false 
        }
        if (($PSBoundParameters.ContainsKey("ActionWorkingPath") -eq $true) `
            -and ($ActionWorkingPath -ne $currentValues.ActionWorkingPath)) 
        { 
            Write-Verbose -Message "ActionWorkingPath does not match desired state. Current value: $($currentValues.ActionWorkingPath) - Desired Value: $ActionWorkingPath"
            return $false 
        }
        if ($ScheduleType -ne $currentValues.ScheduleType) 
        { 
            Write-Verbose -Message "ScheduleType does not match desired state. Current value: $($currentValues.ScheduleType) - Desired Value: $ScheduleType"
            return $false 
        }
        if ($RepeatInterval.TimeOfDay -ne $currentValues.RepeatInterval.TimeOfDay) 
        { 
            Write-Verbose -Message "RepeatInterval does not match desired state. Current value: $($currentValues.RepeatInterval) - Desired Value: $RepeatInterval"
            return $false 
        }
        
        if ($PSBoundParameters.ContainsKey("ExecuteAsCredential") -eq $true) 
        {
            if ($ExecuteAsCredential.UserName -ne $currentValues.ExecuteAsCredential) 
            { 
                Write-Verbose -Message "ExecuteAsCredential does not match desired state. Current value: $($currentValues.ExecuteAsCredential) - Desired Value: $localUser"
                return $false 
            }
        }
        
        if ($PSBoundParameters.ContainsKey("Enable") -eq $true)
        {
            if ($Enable -ne ($currentValues.Enable))
            {
                Write-Verbose -Message "Enable does not match desired state. Current value: $($currentValues.Enabled) - Desired Vale: $Enable"
                return $false
            }
        }
    }
    
    return $true
}
