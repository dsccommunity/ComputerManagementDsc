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

function Remove-CommonParameter
{
    [OutputType([hashtable])]
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [hashtable]
        $Hashtable
    )

    $inputClone = $Hashtable.Clone()
    $commonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters
    $commonParameters += [System.Management.Automation.PSCmdlet]::OptionalCommonParameters

    $Hashtable.Keys | Where-Object { $_ -in $commonParameters } | ForEach-Object {
        $inputClone.Remove($_)
    }

    $inputClone
}

function Test-DscParameterState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)] 
        [hashtable]
        $CurrentValues,

        [Parameter(Mandatory)] 
        [object]
        $DesiredValues,
        
        [string[]]
        $ValuesToCheck,
        
        [switch]$TurnOffTypeChecking
    )

    $returnValue = $true

    $types = 'System.Management.Automation.PSBoundParametersDictionary', 'System.Collections.Hashtable', 'Microsoft.Management.Infrastructure.CimInstance'
    
    if ($DesiredValues.GetType().FullName -notin $types)
    {
        throw ("Property 'DesiredValues' in Test-DscParameterState must be either a Hashtable or CimInstance. Type detected was $($DesiredValues.GetType().Name)")
    }

    if ($DesiredValues.GetType().FullName -eq 'Microsoft.Management.Infrastructure.CimInstance' -and -not $ValuesToCheck)
    {
        throw ("If 'DesiredValues' is a CimInstance then property 'ValuesToCheck' must contain a value")
    }
    
    $DesiredValuesClean = Remove-CommonParameter -Hashtable $DesiredValues

    if (-not $ValuesToCheck)
    {
        $keyList = $DesiredValuesClean.Keys
    } 
    else
    {
        $keyList = $ValuesToCheck
    }

    foreach ($key in $keyList)
    {
        if ($null -ne $DesiredValuesClean.$key)
        {
            $desiredType = $DesiredValuesClean.$key.GetType()
        }
        else
        {
            $desiredType = [psobject]@{ Name = 'Unknown' }
        }
        
        if ($null -ne $CurrentValues.$key)
        {
            $currentType = $CurrentValues.$key.GetType()
        }
        else
        {
            $currentType = [psobject]@{ Name = 'Unknown' }
        }

        if ($currentType.Name -ne 'Unknown' -and $desiredType.Name -eq 'PSCredential')
        {
            # This is a credential object. Compare only the user name
            if ($currentType.Name -eq 'PSCredential' -and $CurrentValues.$key.UserName -eq $DesiredValuesClean.$key.UserName)
            {
                Write-Verbose -Message ('MATCH: PSCredential username match. Current state is {0} and desired state is {1}' -f $CurrentValues.$key.UserName, $DesiredValuesClean.$key.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ('NOTMATCH: PSCredential username mismatch. Current state is {0} and desired state is {1}' -f $CurrentValues.$key.UserName, $DesiredValuesClean.$key.UserName)
                $returnValue = $false
            }
            
            # Assume the string is our username when the matching desired value is actually a credential
            if($currentType.Name -eq 'string' -and $CurrentValues.$key -eq $DesiredValuesClean.$key.UserName)
            {
                Write-Verbose -Message ('MATCH: PSCredential username match. Current state is {0} and desired state is {1}' -f $CurrentValues.$key, $DesiredValuesClean.$key.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ('NOTMATCH: PSCredential username mismatch. Current state is {0} and desired state is {1}' -f $CurrentValues.$key, $DesiredValuesClean.$key.UserName)
                $returnValue = $false
            }
        }
     
        if (-not $TurnOffTypeChecking)
        {   
            if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and
            $desiredType.FullName -ne $currentType.FullName)
            {
                Write-Verbose -Message "NOTMATCH: Type mismatch for property '$key' Current state type is '$($currentType.Name)' and desired type is '$($desiredType.Name)'"
                continue
            }
        }

        if ($CurrentValues.$key -eq $DesiredValuesClean.$key -and -not $desiredType.IsArray)
        {
            Write-Verbose -Message "MATCH: Value (type $($desiredType.Name)) for property '$key' does match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValuesClean.$key)'"
            continue
        }
                    
        if ($DesiredValuesClean.GetType().Name -in 'HashTable', 'PSBoundParametersDictionary')
        {
            $checkDesiredValue = $DesiredValuesClean.ContainsKey($key)
        } 
        else
        {
            $checkDesiredValue = Test-DSCObjectHasProperty -Object $DesiredValuesClean -PropertyName $key
        }
        
        if (-not $checkDesiredValue)
        {
            Write-Verbose -Message "MATCH: Value (type $($desiredType.Name)) for property '$key' does match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValuesClean.$key)'"
            continue
        }
        
        if ($desiredType.IsArray)
        {
            Write-Verbose "Comparing values in property '$key'"
            if (-not $CurrentValues.ContainsKey($key) -or -not $CurrentValues.$key)
            {
                Write-Verbose -Message "NOTMATCH: Value (type $($desiredType.Name)) for property '$key' does not match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValuesClean.$key)'"
                $returnValue = $false
                continue
            }
            elseif ($CurrentValues.$key.Count -ne $DesiredValues.$key.Count)
            {
                Write-Verbose -Message "NOTMATCH: Value (type $($desiredType.Name)) for property '$key' does have a different count. Current state count is '$($CurrentValues.$key.Count)' and desired state count is '$($DesiredValuesClean.$key.Count)'"
                $returnValue = $false
                continue
            }
            else
            {
                $desiredArrayValues = $DesiredValues.$key
                $currentArrayValues = $CurrentValues.$key

                for ($i = 0; $i -lt $desiredArrayValues.Count; $i++)
                {
                    if ($null -ne $desiredArrayValues[$i])
                    {
                        $desiredType = $desiredArrayValues[$i].GetType()
                    }
                    else
                    {
                        $desiredType = [psobject]@{ Name = 'Unknown' }
                    }
                    
                    if ($null -ne $currentArrayValues[$i])
                    {
                        $currentType = $currentArrayValues[$i].GetType()
                    }
                    else
                    {
                        $currentType = [psobject]@{ Name = 'Unknown' }
                    }
                    
                    if (-not $TurnOffTypeChecking)
                    {
                        if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and
                        $desiredType.FullName -ne $currentType.FullName)
                        {
                            Write-Verbose -Message "`tNOTMATCH: Type mismatch for property '$key' Current state type of element [$i] is '$($currentType.Name)' and desired type is '$($desiredType.Name)'"
                            $returnValue = $false
                            continue
                        }
                    }
                        
                    if ($desiredArrayValues[$i] -ne $currentArrayValues[$i])
                    {
                        Write-Verbose -Message "`tNOTMATCH: Value [$i] (type $($desiredType.Name)) for property '$key' does match. Current state is '$($currentArrayValues[$i])' and desired state is '$($desiredArrayValues[$i])'"
                        $returnValue = $false
                        continue
                    }
                    else
                    {
                        Write-Verbose -Message "`tMATCH: Value [$i] (type $($desiredType.Name)) for property '$key' does match. Current state is '$($currentArrayValues[$i])' and desired state is '$($desiredArrayValues[$i])'"
                        continue
                    }
                }
                
            }
        } 
        else {
            if ($DesiredValuesClean.$key -ne $CurrentValues.$key)
            {
                Write-Verbose -Message "NOTMATCH: Value (type $($desiredType.Name)) for property '$key' does not match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValuesClean.$key)'"
                $returnValue = $false
            }
        
        } 
    }
    
    Write-Verbose "Result is '$returnValue'"
    return $returnValue
}

function Test-DSCObjectHasProperty
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory)] 
        [object]
        $Object,

        [Parameter(Mandatory)]
        [string]
        $PropertyName
    )

    if ($Object.PSObject.Properties.Name -contains $PropertyName) 
    {
        return [bool]$Object.$PropertyName
    }
    
    return $false
}

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

    $task = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
    
    if ($null -eq $task) 
    {
        return @{
            TaskName = $TaskName
            ActionExecutable = $ActionExecutable
            Ensure = "Absent"
            ScheduleType = $ScheduleType
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

        if($startAt)
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
            IdleWaitTimeout = $idleWaitTimeout
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
    
    $currentValues = Get-TargetResource @PSBoundParameters
    
    if ($Ensure -eq "Present") 
    {
        if($RepetitionDuration.TimeOfDay -lt $RepeatInterval.TimeOfDay)
        {
            $exceptionObject = New-Object -TypeName System.ArgumentException -ArgumentList `
                    ('Repetition duration {0} is less than repetition interval {1}. Please set RepeatInterval to a value lower or equal to RepetitionDuration' -f $RepetitionDuration.TimeOfDay,$RepeatInterval.TimeOfDay),`
                    'RepeatInterval'
                throw $exceptionObject
        }

        if($ScheduleType -eq 'Daily' -and $DaysInterval -eq 0)
        {
            $exceptionObject = New-Object -TypeName System.ArgumentException -ArgumentList `
                    ('Schedules of the type Daily must have a DaysInterval greater than 0 (value entered: {0})' -f $DaysInterval),`
                    'DaysInterval'
                throw $exceptionObject
        }

        if($ScheduleType -eq 'Weekly' -and $WeeksInterval -eq 0)
        {
            $exceptionObject = New-Object -TypeName System.ArgumentException -ArgumentList `
                    ('Schedules of the type Weekly must have a WeeksInterval greater than 0 (value entered: {0})' -f $WeeksInterval),`
                    'WeeksInterval'
                throw $exceptionObject
        }

        if($ScheduleType -eq 'Weekly' -and $DaysOfWeek.Count -eq 0)
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

        $trigger = New-ScheduledTaskTrigger @triggerArgs

        # To overcome the issue of not being able to set the task repetition for tasks with a schedule type other than Once
        if ($RepeatInterval.TimeOfDay -gt (New-TimeSpan -Seconds 0))
        {
            if ($RepetitionDuration.TimeOfDay -le $RepeatInterval.TimeOfDay)
            {
                $exceptionObject = New-Object System.ArgumentException -ArgumentList `
                    ('Repetition interval is set to {0} but repetition duration is {1}' -f $RepeatInterval.TimeOfDay, $RepetitionDuration.TimeOfDay),`
                    'RepetitionDuration'
                throw $exceptionObject
            }

            $tempTrigger = New-ScheduledTaskTrigger -Once -At 6:6:6 -RepetitionInterval $RepeatInterval.TimeOfDay -RepetitionDuration $RepetitionDuration.TimeOfDay

            Write-Verbose 'Copying values from temporary trigger to property Repetition of $trigger.Repetition'

            $trigger.Repetition = $tempTrigger.Repetition
        }

        if ($currentValues.Ensure -eq "Present") 
        {
            Write-Verbose -Message "Removing previous scheduled task `"$TaskName`""
            Unregister-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath
        }
        
        Write-Verbose -Message "Creating new scheduled task `"$TaskName`""

        $scheduledTask = New-ScheduledTask -Action $action -Trigger $trigger -Settings $setting
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

        Register-ScheduledTask @registerArgs
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
    
    Write-Verbose -Message "Testing scheduled task $TaskName"

    $CurrentValues = Get-TargetResource @PSBoundParameters

    if($Ensure -eq 'Absent' -and $CurrentValues.Ensure -eq 'Absent')
    {
        return $true
    }
    if ($null -eq $CurrentValues) 
    { 
        return $false 
    }
    return Test-DscParameterState -CurrentValues $CurrentValues `
                                    -DesiredValues $PSBoundParameters
}
