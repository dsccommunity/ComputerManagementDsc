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
    -ResourceName 'MSFT_WinEventLog' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

function New-TerminatingError
{
    param
    (
        [Parameter(Mandatory = $true)]
            [String]$errorId,

            [Parameter(Mandatory = $true)]
            [String]$errorMessage,

            [Parameter(Mandatory = $true)]
            [System.Management.Automation.ErrorCategory]$errorCategory
        )

    $exception   = New-Object System.InvalidOperationException $errorMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
    throw $errorRecord
    }

<#
    .SYNOPSIS
        Gets the current resource state.

    .PARAMETER LogName
        Specifies the given name of a eventlog.
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

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $IsEnabled
    )

    $log = Get-WinEvent -ListLog $logName
    $MinimumRetentionDays = Get-EventLog -List | Where-Object {$_.Log -eq $LogName} | Select-Object MinimumRetentionDays

    $returnValue = @{
        LogName = [System.String]$LogName
        LogFilePath = [system.String]$log.LogFilePath
        MaximumSizeInBytes = [System.Int64]$log.MaximumSizeInBytes
        IsEnabled = [System.Boolean]$log.IsEnabled
        LogMode = [System.String]$log.LogMode
        LogRetentionDays = [System.Int32]$MinimumRetentionDays.MinimumRetentionDays
        SecurityDescriptor = [System.String]$log.SecurityDescriptor
    }

    Write-Verbose -Message ($localizedData.GettingEventlogName -f $LogName)
    return $returnValue
}

<#
    .SYNOPSIS
        Sets the desired resource state.

    .PARAMETER LogName
        Specifies the given name of a eventlog.

    .PARAMETER MaximumSizeInBytes
        Specifies the given maximum size in bytes for a specified eventlog.

    .PARAMETER LogMode
        Specifies the given LogMode for a specified eventlog.

    .PARAMETER LogRetentionDays
        Specifies the given LogRetentionDays for the Logmode 'AutoBackup'.

    .PARAMETER SecurityDescriptor
        Specifies the given SecurityDescriptor for a specified eventlog.

    .PARAMETER IsEnabled
        Specifies the given state of a eventlog.

    .PARAMETER LogFilePath
        Specifies the given LogFile path of a eventlog.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $IsEnabled,

        [Parameter()]
        [System.Int64]
        $MaximumSizeInBytes,

        [Parameter()]
        [ValidateSet('AutoBackup','Circular','Retain')]
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

    try
    {
        $log = Get-WinEvent -ListLog $LogName
        Write-Verbose -Message ($localizedData.GettingEventlogName -f $LogName)

        if ($IsEnabled -eq $true)
        {
            if ($PSBoundParameters.ContainsKey('IsEnabled') -and $IsEnabled -ne $log.IsEnabled)
            {
                Write-Verbose -Message ($localizedData.SettingEventlogIsEnabled -f $LogName, $IsEnabled)
                $log.IsEnabled = $IsEnabled
                Save-LogFile -Log $log
                Write-Verbose -Message ($localizedData.SettingWinEventlogIsEnabledSuccess -f $LogName, $IsEnabled)
            }

            if ($PSBoundParameters.ContainsKey('MaximumSizeInBytes') -and $MaximumSizeInBytes -ne $log.MaximumSizeInBytes)
            {
                Write-Verbose -Message ($localizedData.SettingEventlogLogSize -f $LogName, $MaximumSizeInBytes)
                $log.MaximumSizeInBytes = $MaximumSizeInBytes
                Save-LogFile -Log $log
                Write-Verbose -Message ($localizedData.SettingWinEventlogMaximumSizeInBytesSuccess -f $LogName, $MaximumSizeInBytes)
            }

            if ($PSBoundParameters.ContainsKey('LogMode') -and $LogMode -ne $log.LogMode)
            {
                Write-Verbose -Message ($localizedData.SettingEventlogLogMode -f $LogName, $LogMode)
                $log.LogMode = $LogMode
                Save-LogFile -Log $log
                Write-Verbose -Message ($localizedData.SettingWinEventlogLogModeSuccess -f $LogName, $LogMode)
            }

            if ($PSBoundParameters.ContainsKey('LogRetentionDays'))
            {
                if ($LogMode -eq 'AutoBackup' -and (Get-EventLog -List | Where-Object {$_.Log -like $LogName}))
                {
                    $MinimumRetentionDays = Get-EventLog -List | Where-Object {$_.Log -eq $LogName} |
                    Select-Object MinimumRetentionDays

                    if ($LogRetentionDays -ne $MinimumRetentionDays.MinimumRetentionDays)
                    {
                        Set-LogRetentionDays -LogName $LogName -LogRetentionDays $LogRetentionDays
                    }
                }
                else
                {
                    Write-Verbose -Message ($localizedData.EventlogLogRetentionDaysWrongMode -f $LogName)
                }
            }

            if ($PSBoundParameters.ContainsKey('SecurityDescriptor') -and $SecurityDescriptor -ne $log.SecurityDescriptor)
            {
                Write-Verbose -Message ($localizedData.SettingEventlogSecurityDescriptor -f $LogName, $SecurityDescriptor)
                $log.SecurityDescriptor = $SecurityDescriptor
                Save-LogFile -Log $log
                Write-Verbose -Message ($localizedData.SettingWinEventlogSecurityDescriptorSuccess -f $LogName, $SecurityDescriptor)
            }

            if ($PSBoundParameters.ContainsKey('LogFilePath') -and $LogFilePath -ne $log.LogFilePath)
            {
                Write-Verbose -Message ($localizedData.SettingEventlogLogFilePath -f $LogName, $LogFilePath)
                $log.LogFilePath = $LogFilePath
                Save-LogFile -Log $log
                Write-Verbose -Message ($localizedData.SettingWinEventlogLogFilePathSuccess -f $LogName, $LogFilePath)
            }
        }
        else
        {
            Write-Verbose -Message ($localizedData.SettingEventlogIsEnabled -f $LogName, $IsEnabled)
            $log.IsEnabled = $IsEnabled
            Save-LogFile -Log $log
            Write-Verbose -Message ($localizedData.SettingWinEventlogIsEnabledSuccess -f $LogName, $IsEnabled)
        }
    }
    catch
    {
        write-Debug "ERROR: $($_ | Format-List * -force | Out-String)"
        New-TerminatingError -errorId 'GetWinEventLogFailed' -errorMessage $_.Exception -errorCategory InvalidOperation
    }
}

<#
    .SYNOPSIS
        Tests if the current resource state matches the desired resource state.

    .PARAMETER LogName
        Specifies the given name of a eventlog.

    .PARAMETER MaximumSizeInBytes
        Specifies the given maximum size in bytes for a specified eventlog.

    .PARAMETER LogMode
        Specifies the given LogMode for a specified eventlog.

    .PARAMETER LogRetentionDays
        Specifies the given LogRetentionDays for the Logmode 'AutoBackup'.

    .PARAMETER SecurityDescriptor
        Specifies the given SecurityDescriptor for a specified eventlog.

    .PARAMETER IsEnabled
        Specifies the given state of a eventlog.

    .PARAMETER LogFilePath
        Specifies the given LogFile path of a eventlog.
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

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $IsEnabled,

        [Parameter()]
        [ValidateRange(1028kb,18014398509481983kb)]
        [System.Int64]
        $MaximumSizeInBytes,

        [Parameter()]
        [ValidateSet('AutoBackup','Circular','Retain')]
        [System.String]
        $LogMode,

        [Parameter()]
        [ValidateRange(1,365)]
        [System.Int32]
        $LogRetentionDays,

        [Parameter()]
        [System.String]
        $SecurityDescriptor,

        [Parameter()]
        [System.String]
        $LogFilePath
    )

    $log = Get-WinEvent -ListLog $LogName -ErrorAction SilentlyContinue
    $desiredState = $true

    if ($IsEnabled -eq $true)
    {

        if ($PSBoundParameters.ContainsKey('IsEnabled') -and $log.IsEnabled -ne $IsEnabled)
        {
            Write-Verbose -Message ($localizedData.TestingEventlogIsEnabled -f $LogName, $IsEnabled)
            $desiredState = $false
        }
        else
        {
            Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'IsEnabled')
        }

        if ($PSBoundParameters.ContainsKey('MaximumSizeInBytes') -and $log.MaximumSizeInBytes -ne $MaximumSizeInBytes)
        {
            Write-Verbose -Message ($localizedData.TestingEventlogMaximumSizeInBytes -f $LogName, $MaximumSizeInBytes)
            $desiredState = $false
        }
        else
        {
            Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'MaximumSizeInBytes')
        }

        if ($PSBoundParameters.ContainsKey('LogMode') -and $log.LogMode -ne $LogMode)
        {
            Write-Verbose -Message ($localizedData.TestingEventlogLogMode -f $LogName, $LogMode)
            $desiredState = $false
        }
        else
        {
            Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'LogMode')
        }

        if ($PSBoundParameters.ContainsKey('LogRetentionDays'))
        {
            if ($LogMode -eq 'AutoBackup' -and (Get-EventLog -List | Where-Object {$_.Log -like $LogName}))
            {
                $MinimumRetentionDays = Get-EventLog -List | Where-Object {$_.Log -eq $LogName} |
                Select-Object MinimumRetentionDays

                if ($LogRetentionDays -ne $MinimumRetentionDays.MinimumRetentionDays)
                {
                    Write-Verbose -Message ($localizedData.TestingEventlogLogRetentionDays -f $LogName, $LogRetentionDays)
                    $desiredState = $false
                }
                else
                {
                    Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'LogRetentionDays')
                }
            }
            else
            {
                Write-Verbose -Message ($localizedData.EventlogLogRetentionDaysWrongMode -f $LogName)
                $desiredState = $false
            }
        }

        if ($PSBoundParameters.ContainsKey('LogFilePath') -and $log.LogFilePath -ne $LogFilePath)
        {
            Write-Verbose -Message ($localizedData.TestingWinEventlogLogFilePath -f $LogName, $LogFilePath)
            $desiredState = $false
        }
        else
        {
            Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'LogFilePath')
        }

        if ($PSBoundParameters.ContainsKey('SecurityDescriptor') -and $log.SecurityDescriptor -ne $SecurityDescriptor)
        {
            Write-Verbose -Message ($localizedData.TestingWinEventlogSecurityDescriptor -f $LogName, $SecurityDescriptor)
            $desiredState = $false
        }
        else
        {
            Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'SecurityDescriptor')
        }
    }
    else
    {
        if ($PSBoundParameters.ContainsKey('IsEnabled') -and $log.IsEnabled -ne $IsEnabled)
        {
            Write-Verbose -Message ($localizedData.TestingEventlogIsEnabled -f $LogName, $IsEnabled)
            $desiredState = $false
        }
        else
        {
            Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'IsEnabled')
        }
    }
    return $desiredState
}

<#
    .SYNOPSIS
        Save the desired resource state.

    .PARAMETER Log
        Specifies the given object of a eventlog.
#>
Function Save-LogFile
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
        Write-Verbose -Message ($localizedData.SaveWinEventlogSuccess)
    }
    catch
    {
        Write-Verbose -Message ($localizedData.SaveWinEventlogFailure)
    }
}

<#
    .SYNOPSIS
        Sets the desired resource state.

    .PARAMETER LogName
        Specifies the given name of a eventlog.

    .PARAMETER Retention
        Specifies the given RetentionDays for LogMode Autobackup.
#>
Function Set-LogRetentionDays
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

    Write-Verbose -Message ($localizedData.SettingEventlogLogRetentionDays -f $LogName, $LogRetentionDays)

    try
    {
        Limit-Eventlog -LogName $LogName -OverflowAction 'OverwriteOlder' -RetentionDays $LogRetentionDays
        Write-Verbose -Message ($localizedData.SettingWinEventlogRetentionDaysSuccess -f $LogName, $LogRetentionDays)
    }
    catch
    {
        Write-Verbose -Message ($localizedData.SettingWinEventlogRetentionDaysFailed -f $LogName, $LogRetentionDays)
    }
}

Export-ModuleMember -Function *-TargetResource
