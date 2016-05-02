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
        $trigger = New-ScheduledTaskTrigger -Once -At $startTime `
                                            -RepetitionInterval $repeatAt `
                                            -RepetitionDuration ([TimeSpan]::MaxValue)
        
        if ($currentValues.Ensure -eq "Absent") 
        {
            Write-Verbose -Message "Creating new scheduled task `"$TaskName`""

            $scheduledTask = New-ScheduledTask -Action $action -Trigger $trigger            
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
            return $false 
        }
        if ($ActionExecutable -ne $currentValues.ActionExecutable) 
        { 
            return $false 
        }
        if (($PSBoundParameters.ContainsKey("ActionArguments") -eq $true) `
            -and ($ActionArguments -ne $currentValues.ActionArguments)) 
        { 
            return $false 
        }
        if (($PSBoundParameters.ContainsKey("ActionWorkingPath") -eq $true) `
            -and ($ActionWorkingPath -ne $currentValues.ActionWorkingPath)) 
        { 
            return $false 
        }
        if ($ScheduleType -ne $currentValues.ScheduleType) 
        { 
            return $false 
        }
        if ($RepeatInterval -ne $currentValues.RepeatInterval) 
        { 
            return $false 
        }
        
        if ($PSBoundParameters.ContainsKey("ExecuteAsCredential") -eq $true) 
        {
            if ($ExecuteAsCredential.UserName.Contains('\') -eq $true) 
            {
                $localUser = $ExecuteAsCredential.UserName.Split('\')[1]    
            } 
            else 
            {
                $localUser = $ExecuteAsCredential.UserName
            }
            if ($localUser -ne $currentValues.ExecuteAsCredential) 
            { 
                return $false 
            }
        }
    }
    
    return $true
}
