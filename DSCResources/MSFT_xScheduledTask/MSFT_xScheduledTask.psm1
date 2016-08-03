function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory=$true)]
        [System.String]
        $TaskName,
        
        [Parameter(Mandatory=$false)]
        [System.String]
        $TaskPath = "\",
        
        [Parameter(Mandatory=$true)]
        [System.String]
        $ActionExecutable,
        
        [Parameter(Mandatory=$false)]
        [System.String]
        $ActionArguments,
        
        [Parameter(Mandatory=$false)]
        [System.String]
        $ActionWorkingPath,
        
        [Parameter(Mandatory=$true)]
        [System.String]
        [ValidateSet("Minutes", "Hourly", "Daily")] $ScheduleType,
        
        [Parameter(Mandatory=$true)]
        [System.UInt32]
        $RepeatInterval,
        
        [Parameter(Mandatory=$false)]
        [System.String]
        $StartTime = "12:00 AM",
        
        [Parameter(Mandatory=$false)]
        [System.String]
        [ValidateSet("Present","Absent")]
        $Ensure = "Present",
        
        [Parameter(Mandatory=$false)]
        [System.Boolean]
        $Enable,
        
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]
        $ExecuteAsCredential
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
        $action = $task.Actions | Select -First 1
        $trigger = $task.Triggers | Select -First 1
        $repetition = $trigger.Repetition
        $returnScheduleType = "Unknown"
        $returnInveral = 0
        
        # Check for full formatting 
        if ($repetition.Interval -like "P*DT*H*M*S") 
        {
            $timespan = [Timespan]::Parse(($repetition.Interval -replace "P" -replace "DT", ":" -replace "H", ":" -replace "M", ":" -replace "S"))
            
            if ($timespan.Days -ge 1) 
            {
                $returnScheduleType = "Daily"
                $returnInveral = $timespan.TotalDays
            }
            elseif ($timespan.Hours -ge 1 -and $timespan.Minutes -eq 0) 
            {
                $returnScheduleType = "Hourly"
                $returnInveral = $timespan.TotalHours
            }
            elseif ($timespan.Minutes -ge 1) 
            {
                $returnScheduleType = "Minutes"
                $returnInveral = $timespan.TotalMinutes
            }
        } 
        else 
        {
            if ($repetition.Duration -eq $null -and $repetition.Interval -eq $null) 
            {
                $returnScheduleType = "Daily"
                $returnInveral = $trigger.DaysInterval
            }
            if ($repetition.Duration -eq $null -and $repetition.Interval -like "P*D") 
            {
                $returnScheduleType = "Daily"
                [System.Uint32]$returnInveral = $repetition.Interval -replace "P" -replace "D"
            }
            if ($repetition.Duration -eq $null -and $repetition.Interval -like "P*D*") 
            {
                $returnScheduleType = "Daily"
                [System.Uint32]$returnInveral = $repetition.Interval.Substring(0, $repetition.Interval.IndexOf('D')) -replace "P"
            }
            if (($repetition.Duration -eq "P1D" -or $repetition.Duration -eq $null) `
                    -and $repetition.Interval -like "PT*H") 
            {
                $returnScheduleType = "Hourly"
                [System.Uint32]$returnInveral = $repetition.Interval -replace "PT" -replace "H"
            }
            if (($repetition.Duration -eq "P1D" -or $repetition.Duration -eq $null) `
                    -and $repetition.Interval -like "PT*M") 
            {
                $returnScheduleType = "Minutes"
                if ($repetition.Interval.Contains('H')) 
                {
                    $timeToParse = ($repetition.Interval -replace "PT" -replace "H",":" -replace "M")
                    [System.Uint32]$returnInveral = [TimeSpan]::Parse($timeToParse).TotalMinutes
                } 
                else 
                {
                    [System.Uint32]$returnInveral = $repetition.Interval -replace "PT" -replace "M"
                }
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
            RepeatInterval = $returnInveral
            ExecuteAsCredential = $task.Principal.UserId
            Enable = $task.Settings.Enabled
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
        
        [Parameter(Mandatory=$false)]
        [System.String]
        $TaskPath = "\",
        
        [Parameter(Mandatory=$true)]
        [System.String]
        $ActionExecutable,
        
        [Parameter(Mandatory=$false)]
        [System.String]
        $ActionArguments,
        
        [Parameter(Mandatory=$false)]
        [System.String]
        $ActionWorkingPath,
        
        [Parameter(Mandatory=$true)]
        [System.String]
        [ValidateSet("Minutes", "Hourly", "Daily")] $ScheduleType,
        
        [Parameter(Mandatory=$true)]
        [System.UInt32]
        $RepeatInterval,
        
        [Parameter(Mandatory=$false)]
        [System.String]
        $StartTime = "12:00 AM",
        
        [Parameter(Mandatory=$false)]
        [System.String]
        [ValidateSet("Present","Absent")]
        $Ensure = "Present",
        
        [Parameter(Mandatory=$false)]
        [System.Boolean]
        $Enable,
        
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]
        $ExecuteAsCredential
    )
    
    $currentValues = Get-TargetResource @PSBoundParameters
    
    if ($Ensure -eq "Present") 
    {
        $actionArgs = @{
            Execute = $ActionExecutable
        }
        if ($PSBoundParameters.ContainsKey("ActionArguments")) 
        { 
            $actionArgs.Add("Argument", $ActionArguments)
        }
        if ($PSBoundParameters.ContainsKey("ActionWorkingPath")) 
        { 
            $actionArgs.Add("WorkingDirectory", $ActionWorkingPath)
        }
        $action = New-ScheduledTaskAction @actionArgs
        
        $settingArgs = @{}
            
        if ($PSBoundParameters.ContainsKey("Enable"))
        {
            $settingArgs.Add("Disable", (-not $Enable))
        }
        
        $setting = New-ScheduledTaskSettingsSet @settingArgs
        
        $date = (Get-Date).Date
        $startTime = [DateTime]::Parse("$($date.ToShortDateString()) $StartTime")
        switch ($ScheduleType) 
        {
            "Minutes" 
            { 
                $repeatAt = New-TimeSpan -Minutes $RepeatInterval
            }
            "Hourly" 
            { 
                $repeatAt = New-TimeSpan -Hours $RepeatInterval
            }
            "Daily" 
            { 
                $repeatAt = New-TimeSpan -Days $RepeatInterval
            }
        }
        try
        {
            $trigger = New-ScheduledTaskTrigger -Once -At $startTime `
                                                -RepetitionInterval $repeatAt 
        }
        catch
        {
            $trigger = New-ScheduledTaskTrigger -Once -At $startTime `
                                                -RepetitionInterval $repeatAt `
                                                -RepetitionDuration ([TimeSpan]::MaxValue)
        }
        
        if ($currentValues.Ensure -eq "Absent") 
        {
            Write-Verbose -Message "Creating new scheduled task `"$TaskName`""

            $scheduledTask = New-ScheduledTask -Action $action -Trigger $trigger -Settings $setting
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
        
        [Parameter(Mandatory=$false)]
        [System.String]
        $TaskPath = "\",
        
        [Parameter(Mandatory=$true)]
        [System.String]
        $ActionExecutable,
        
        [Parameter(Mandatory=$false)]
        [System.String]
        $ActionArguments,
        
        [Parameter(Mandatory=$false)]
        [System.String]
        $ActionWorkingPath,
        
        [Parameter(Mandatory=$true)]
        [System.String]
        [ValidateSet("Minutes", "Hourly", "Daily")] $ScheduleType,
        
        [Parameter(Mandatory=$true)]
        [System.UInt32]
        $RepeatInterval,
        
        [Parameter(Mandatory=$false)]
        [System.String]
        $StartTime = "12:00 AM",
        
        [Parameter(Mandatory=$false)]
        [System.String]
        [ValidateSet("Present","Absent")]
        $Ensure = "Present",
        
        [Parameter(Mandatory=$false)]
        [System.Boolean]
        $Enable,
        
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]
        $ExecuteAsCredential
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
        if ($RepeatInterval -ne $currentValues.RepeatInterval) 
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
