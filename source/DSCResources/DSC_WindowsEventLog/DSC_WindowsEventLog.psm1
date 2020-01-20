$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'DSC_WindowsEventLog'

<#
    .SYNOPSIS
        Gets the current state of the Windows Event Log.

    .PARAMETER LogName
        Specifies the given name of a Windows Event Log.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        [Parameter()]
        [System.Boolean]
        $IsEnabled
    )

    $log = Get-WindowsEventLog -LogName $LogName

    $LogRetentionDays = (Get-EventLog -List | Where-Object -Property Log -eq $LogName).minimumRetentionDays

    $returnValue = @{
        LogName            = [System.String] $LogName
        LogFilePath        = [system.String] $log.LogFilePath
        MaximumSizeInBytes = [System.Int64] $log.MaximumSizeInBytes
        IsEnabled          = [System.Boolean] $log.IsEnabled
        LogMode            = [System.String] $log.LogMode
        SecurityDescriptor = [System.String] $log.SecurityDescriptor
        LogRetentionDays   = [System.Int32] $logRetentionDays
    }

    Write-Verbose -Message ($script:localizedData.GettingEventlogName -f $LogName)
    return $returnValue
}

<#
    .SYNOPSIS
        Sets the current state of the Windows Event Log.

    .PARAMETER LogName
        Specifies the given name of a Windows Event Log.

    .PARAMETER MaximumSizeInBytes
        Specifies the given maximum size in bytes for a specified Windows Event Log.

    .PARAMETER LogMode
        Specifies the given LogMode for a specified Windows Event Log.

    .PARAMETER LogRetentionDays
        Specifies the given LogRetentionDays for the Logmode 'AutoBackup'.

    .PARAMETER SecurityDescriptor
        Specifies the given SecurityDescriptor for a specified Windows Event Log.

    .PARAMETER IsEnabled
        Specifies the given state of a Windows Event Log.

    .PARAMETER LogFilePath
        Specifies the given LogFile path of a Windows Event Log.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        [Parameter()]
        [System.Boolean]
        $IsEnabled,

        [Parameter()]
        [System.Int64]
        $MaximumSizeInBytes,

        [Parameter()]
        [ValidateSet('AutoBackup', 'Circular', 'Retain')]
        [System.String]
        $LogMode,

        [Parameter()]
        [System.Int32]
        $LogRetentionDays,

        [Parameter()]
        [System.String]
        $SecurityDescriptor,

        [Parameter()]
        [System.String]
        $LogFilePath
    )

    $log = Get-WindowsEventLog -LogName $LogName

    if ($null -eq $log)
    {
        return
    }

    $shouldSaveLogFile = $false

    Write-Verbose -Message ($script:localizedData.GettingEventlogName -f $LogName)

    if ($IsEnabled -eq $true)
    {
        if ($PSBoundParameters.ContainsKey('IsEnabled') -and $IsEnabled -ne $log.IsEnabled)
        {
            Write-Verbose -Message ($script:localizedData.SettingEventlogIsEnabled -f $LogName, $IsEnabled)
            $log.IsEnabled = $IsEnabled
            $shouldSaveLogFile = $true
        }

        if ($PSBoundParameters.ContainsKey('MaximumSizeInBytes') -and $MaximumSizeInBytes -ne $log.MaximumSizeInBytes)
        {
            Write-Verbose -Message ($script:localizedData.SettingEventlogLogSize -f $LogName, $MaximumSizeInBytes)
            $log.MaximumSizeInBytes = $MaximumSizeInBytes
            $shouldSaveLogFile = $true
        }

        if ($PSBoundParameters.ContainsKey('LogMode') -and $LogMode -ne $log.LogMode)
        {
            Write-Verbose -Message ($script:localizedData.SettingEventlogLogMode -f $LogName, $LogMode)
            $log.LogMode = $LogMode
            $shouldSaveLogFile = $true
        }

        if ($PSBoundParameters.ContainsKey('SecurityDescriptor') -and $SecurityDescriptor -ne $log.SecurityDescriptor)
        {
            Write-Verbose -Message ($script:localizedData.SettingEventlogSecurityDescriptor -f $LogName, $SecurityDescriptor)
            $log.SecurityDescriptor = $SecurityDescriptor
            $shouldSaveLogFile = $true
        }

        if ($PSBoundParameters.ContainsKey('LogFilePath') -and $LogFilePath -ne $log.LogFilePath)
        {
            Write-Verbose -Message ($script:localizedData.SettingEventlogLogFilePath -f $LogName, $LogFilePath)
            $log.LogFilePath = $LogFilePath
            $shouldSaveLogFile = $true
        }
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.SettingEventlogIsEnabled -f $LogName, $IsEnabled)
        $log.IsEnabled = $IsEnabled
        $shouldSaveLogFile = $true
    }

    if ($shouldSaveLogFile -eq $true)
    {
        Save-LogFile -Log $log
    }

    if ($PSBoundParameters.ContainsKey('LogRetentionDays'))
    {
        if ($LogMode -eq 'AutoBackup' -and (Get-EventLog -List | Where-Object -FilterScript {$_.Log -like $LogName}))
        {
            $matchingEventLog = Get-EventLog -List | Where-Object -FilterScript {
                $_.Log -eq $LogName
            }

            $minimumRetentionDaysForLog = $matchingEventLog.minimumRetentionDays

            if ($LogRetentionDays -ne $minimumRetentionDaysForLog)
            {
                Set-LogRetentionDays -LogName $LogName -LogRetentionDays $LogRetentionDays
            }
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.EventlogLogRetentionDaysWrongMode -f $LogName)
        }
    }
}

<#
    .SYNOPSIS
        Tests if the the current state of the Windows Event Log is in the desired state.

    .PARAMETER LogName
        Specifies the given name of a Windows Event Log.

    .PARAMETER MaximumSizeInBytes
        Specifies the given maximum size in bytes for a specified Windows Event Log.

    .PARAMETER LogMode
        Specifies the given LogMode for a specified evWindows Event Logentlog.

    .PARAMETER LogRetentionDays
        Specifies the given LogRetentionDays for the Logmode 'AutoBackup'.

    .PARAMETER SecurityDescriptor
        Specifies the given SecurityDescriptor for a specified Windows Event Log.

    .PARAMETER IsEnabled
        Specifies the given state of a Windows Event Log.

    .PARAMETER LogFilePath
        Specifies the given LogFile path of a Windows Event Log.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        [Parameter()]
        [System.Boolean]
        $IsEnabled,

        [Parameter()]
        [ValidateRange(1028kb, 18014398509481983kb)]
        [System.Int64]
        $MaximumSizeInBytes,

        [Parameter()]
        [ValidateSet('AutoBackup', 'Circular', 'Retain')]
        [System.String]
        $LogMode,

        [Parameter()]
        [ValidateRange(1, 365)]
        [System.Int32]
        $LogRetentionDays,

        [Parameter()]
        [System.String]
        $SecurityDescriptor,

        [Parameter()]
        [System.String]
        $LogFilePath
    )

    $log = Get-WindowsEventLog -LogName $LogName

    if ($null -eq $log)
    {
        return
    }

    $desiredState = $true

    if ($IsEnabled -eq $true)
    {
        if ($PSBoundParameters.ContainsKey('IsEnabled') -and $log.IsEnabled -ne $IsEnabled)
        {
            Write-Verbose -Message ($script:localizedData.TestingEventlogIsEnabled -f $LogName, $IsEnabled)
            $desiredState = $false
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.SetResourceIsInDesiredState -f $LogName, 'IsEnabled')
        }

        if ($PSBoundParameters.ContainsKey('MaximumSizeInBytes') -and $log.MaximumSizeInBytes -ne $MaximumSizeInBytes)
        {
            Write-Verbose -Message ($script:localizedData.TestingEventlogMaximumSizeInBytes -f $LogName, $MaximumSizeInBytes)
            $desiredState = $false
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.SetResourceIsInDesiredState -f $LogName, 'MaximumSizeInBytes')
        }

        if ($PSBoundParameters.ContainsKey('LogMode') -and $log.LogMode -ne $LogMode)
        {
            Write-Verbose -Message ($script:localizedData.TestingEventlogLogMode -f $LogName, $LogMode)
            $desiredState = $false
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.SetResourceIsInDesiredState -f $LogName, 'LogMode')
        }

        if ($PSBoundParameters.ContainsKey('LogRetentionDays'))
        {
            if ($LogMode -eq 'AutoBackup')
            {
                $minimumRetentionDays = Get-EventLog -List | Where-Object -FilterScript { $_.Log -eq $LogName }

                if ($LogRetentionDays -ne $minimumRetentionDays.minimumRetentionDays)
                {
                    Write-Verbose -Message ($script:localizedData.TestingEventlogLogRetentionDays -f $LogName, $LogRetentionDays)
                    $desiredState = $false
                }
                else
                {
                    Write-Verbose -Message ($script:localizedData.SetResourceIsInDesiredState -f $LogName, 'LogRetentionDays')
                }
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.EventlogLogRetentionDaysWrongMode -f $LogName)
                $desiredState = $false
            }
        }

        if ($PSBoundParameters.ContainsKey('LogFilePath') -and $log.LogFilePath -ne $LogFilePath)
        {
            Write-Verbose -Message ($script:localizedData.TestingWindowsEventlogLogFilePath -f $LogName, $LogFilePath)
            $desiredState = $false
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.SetResourceIsInDesiredState -f $LogName, 'LogFilePath')
        }

        if ($PSBoundParameters.ContainsKey('SecurityDescriptor') -and $log.SecurityDescriptor -ne $SecurityDescriptor)
        {
            Write-Verbose -Message ($script:localizedData.TestingWindowsEventlogSecurityDescriptor -f $LogName, $SecurityDescriptor)
            $desiredState = $false
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.SetResourceIsInDesiredState -f $LogName, 'SecurityDescriptor')
        }
    }
    else
    {
        if ($PSBoundParameters.ContainsKey('IsEnabled') -and $log.IsEnabled -ne $IsEnabled)
        {
            Write-Verbose -Message ($script:localizedData.TestingEventlogIsEnabled -f $LogName, $IsEnabled)
            $desiredState = $false
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.SetResourceIsInDesiredState -f $LogName, 'IsEnabled')
        }
    }
    return $desiredState
}

<#
    .SYNOPSIS
        Helper function for the Windows Event Log.

    .PARAMETER Log
        Gets the specified Windows Event Log properties.
#>
function Get-WindowsEventLog
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName
    )

    $log = Get-WinEvent -ListLog $LogName

    if (!$log)
    {
        Write-Warning `
            -Message ($script:localizedData.WindowsEventLogNotFound -f $LogName)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.WindowsEventLogFound -f $LogName)
        return $log
    }
}

<#
    .SYNOPSIS
        Save the Windows Event Log properties.

    .PARAMETER Log
        Specifies the given object of a Windows Event Log.
#>
function Save-LogFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Log
    )

    try
    {
        $Log.SaveChanges()
        Write-Verbose -Message ($script:localizedData.SaveWindowsEventlogSuccess)
    }
    catch
    {
        Write-Verbose -Message ($script:localizedData.SaveWindowsEventlogFailure)
    }
}

<#
    .SYNOPSIS
        Set the Log Retention for a Windows Event Log.

    .PARAMETER LogName
        Specifies the given name of a Windows Event Log.

    .PARAMETER Retention
        Specifies the given RetentionDays for LogMode Autobackup.
#>
function Set-LogRetentionDays
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $LogRetentionDays
    )

    Write-Verbose -Message ($script:localizedData.SettingEventlogLogRetentionDays -f $LogName, $LogRetentionDays)

    try
    {
        Limit-Eventlog -LogName $LogName -OverflowAction 'OverwriteOlder' -RetentionDays $LogRetentionDays
        Write-Verbose -Message ($script:localizedData.SettingWindowsEventlogRetentionDaysSuccess -f $LogName, $LogRetentionDays)
    }
    catch
    {
        Write-Verbose -Message ($script:localizedData.SettingWindowsEventlogRetentionDaysFailed -f $LogName, $LogRetentionDays)
    }
}

Export-ModuleMember -Function *-TargetResource
