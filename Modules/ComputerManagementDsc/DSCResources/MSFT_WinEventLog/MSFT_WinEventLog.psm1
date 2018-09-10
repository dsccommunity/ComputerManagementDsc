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

<#
    .SYNOPSIS
        Gets the current resource state.

    .PARAMETER errorId
        Specifies the given errorid.

    .PARAMETER errorMessage
        Specifies the given error message.

    .PARAMETER errorCategory
        Specifies the given error category.
#>
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
        $LogName
    )

    try
    {
        $log = Get-WinEvent -ListLog $logName
        $MinimumRetentionDays = Get-EventLog -List | Where-Object {$_.Log -eq $logName} | Select-Object MinimumRetentionDays

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
    catch
    {
        write-Debug "ERROR: $($_ | Format-List * -force | Out-String)"
        New-TerminatingError -errorId 'GetWinEventLogFailed' -errorMessage $_.Exception -errorCategory InvalidOperation
    }
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

        [Parameter()]
        [System.Int64]
        $MaximumSizeInBytes,

        [Parameter()]
        [System.Boolean]
        $IsEnabled,

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
        $LogName = "Application"
        $MaximumSizeInBytes = "4194304"
        $Logmode = "Circular"
        $log = Get-WinEvent -ListLog $LogName
        Write-Verbose -Message ($localizedData.GettingEventlogName -f $LogName)
        $MinimumRetentionDays = Get-EventLog -List | Where-Object {$_.Log -eq "$LogName"} | Select-Object MinimumRetentionDays
        Write-Verbose -Message ($localizedData.GettingEventlogLogModeRetention -f $LogName)
        $update = $false

        if ($PSBoundParameters.ContainsKey('MaximumSizeInBytes') -and $MaximumSizeInBytes -ne $log.MaximumSizeInBytes)
        {
            Write-Verbose -Message ($localizedData.SettingEventlogLogSize -f $LogName, $MaximumSizeInBytes)
            Set-MaximumSizeInBytes -LogName $LogName -MaximumSizeInBytes $MaximumSizeInBytes
        }

        if ($PSBoundParameters.ContainsKey('LogMode') -and $LogMode -ne $log.LogMode)
        {
            if($Logmode -ne 'AutoBackup')
            {
                Write-Verbose -Message ($localizedData.SettingEventlogLogMode -f $LogName, $LogMode, $MaximumSizeInBytes)
                Set-LogMode -LogName $LogName -LogMode $LogMode -MaximumSizeInBytes $MaximumSizeInBytes
            }
            else
            {
                Write-Verbose -Message ($localizedData.SettingEventlogLogRetention -f $LogName, $LogMode, $MinimumRetentionDays)
                Set-LogMode -LogName $LogName -LogMode $LogMode -LogRetentionDays $LogRetentionDays
            }
        }

        if ($PSBoundParameters.ContainsKey('SecurityDescriptor') -and $SecurityDescriptor -ne $log.SecurityDescriptor)
        {
            Set-SecurityDescriptor -LogName $LogName -SecurityDescriptor $SecurityDescriptor
        }

        if ($PSBoundParameters.ContainsKey('IsEnabled') -and $IsEnabled -ne $log.IsEnabled)
        {
            Set-IsEnabled -LogName $LogName -IsEnabled $IsEnabled
        }

        if ($PSBoundParameters.ContainsKey('LogFilePath') -and $LogFilePath -ne $log.LogFilePath)
        {
            Set-LogFilePath -LogName $LogName -LogFilePath $LogFilePath
        }
    }
    catch
    {
        write-Debug "ERROR: $($_ | Format-List * -force | Out-String)"
        New-TerminatingError -errorId 'SetWinEventLogFailed' -errorMessage $_.Exception -errorCategory InvalidOperation
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

        [Parameter()]
        [System.Int64]
        $MaximumSizeInBytes,

        [Parameter()]
        [System.Boolean]
        $IsEnabled,

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
        $log = Get-WinEvent -ListLog $logName
        Write-Verbose -Message ($localizedData.GettingEventlogName -f $LogName)

        if ($PSBoundParameters.ContainsKey('MaximumSizeInBytes') -and $log.MaximumSizeInBytes -ne $MaximumSizeInBytes)
        {
            Write-Verbose -Message ($localizedData.TestingWinEventlogLogSize -f $LogName, $MaximumSizeInBytes)
            Write-Verbose -Message ($localizedData.SetResourceNotInDesiredState -f $LogName, 'MaximumSizeInBytes',$LogRetentionDays)
            return $false
        }
        else
        {
            Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'MaximumSizeInBytes',$LogRetentionDays)
        }

        if ($PSBoundParameters.ContainsKey('IsEnabled') -and $log.IsEnabled -ne $IsEnabled)
        {
            Write-Verbose -Message ($localizedData.TestingWinEventlogIsEnabled -f $LogName, $IsEnabled)
            Write-Verbose -Message ($localizedData.SetResourceNotInDesiredState -f $LogName, 'IsEnabled',$LogRetentionDays)
            return $false
        }
        else
        {
            Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'IsEnabled',$LogRetentionDays)
        }

        if ($PSBoundParameters.ContainsKey('LogMode') -and $log.LogMode -ne $LogMode)
        {
            Write-Verbose -Message ($localizedData.TestingWinEventlogLogMode -f $LogName, $LogMode)
            Write-Verbose -Message ($localizedData.SetResourceNotInDesiredState -f $LogName, 'LogMode',$LogRetentionDays)
            return $false
        }
        else
        {
            Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'LogMode',$LogRetentionDays)
        }

        if ($PSBoundParameters.ContainsKey('LogRetentionDays') -and $LogRetentionDays -ne $MinimumRetentionDays.MinimumRetentionDays)
        {
            Write-Verbose -Message ($localizedData.TestingWinEventlogLogRetention -f $LogName, $LogRetentionDays)
            Write-Verbose -Message ($localizedData.SetResourceNotInDesiredState -f $LogName, 'LogRetentionDays',$LogRetentionDays)
            return $false
        }
        else
        {
            Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'LogRetentionDays',$LogRetentionDays)
        }

        if ($PSBoundParameters.ContainsKey('SecurityDescriptor') -and $log.SecurityDescriptor -ne $SecurityDescriptor)
        {
            Write-Verbose -Message ($localizedData.TestingWinEventlogSecurityDescriptor -f $LogName, $SecurityDescriptor)
            Write-Verbose -Message ($localizedData.SetResourceNotInDesiredState -f $LogName, 'SecurityDescriptor',$LogRetentionDays)
            return $false
        }
        else
        {
            Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'SecurityDescriptor',$LogRetentionDays)
        }

        if ($PSBoundParameters.ContainsKey('LogFilePath') -and $log.LogFilePath -ne $LogFilePath)
        {
            Write-Verbose -Message ($localizedData.TestingWinEventlogLogFilePath -f $LogName, $LogFilePath)
            Write-Verbose -Message ($localizedData.SetResourceNotInDesiredState -f $LogName, 'LogFilePath',$LogRetentionDays)
            return $false
        }
        else
        {
            Write-Verbose -Message ($localizedData.SetResourceIsInDesiredState -f $LogName, 'LogFilePath',$LogRetentionDays)
        }

        return $true
    }
    catch
    {
        write-Debug "ERROR: $($_ | Format-List * -force | Out-String)"
        New-TerminatingError -errorId 'TestWinEventLogFailed' -errorMessage $_.Exception -errorCategory InvalidOperation
    }
}

<#
    .SYNOPSIS
        Sets the desired resource state.

    .PARAMETER LogName
        Specifies the given name of a eventlog.

    .PARAMETER MaximumSizeInBytes
        Specifies the given maximum size in bytes for a specified eventlog.
#>
Function Set-MaximumSizeInBytes
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.String]
        $LogName,

        [Parameter()]
        [System.Int64]
        $MaximumSizeInBytes
    )

    Write-Verbose -Message ($localizedData.SettingEventlogLogSize -f $LogName, $MaximumSizeInBytes)

    try
    {
        Limit-EventLog -LogName $LogName -MaximumSize $MaximumSizeInBytes
        Write-Verbose -Message ($localizedData.SettingWinEventlogMaximumSizeInBytesSuccess -f $LogName, $MaximumSizeInBytes)
    }
    catch
    {
        Write-Verbose -Message ($localizedData.SettingWinEventlogMaximumSizeInBytesFailed -f $LogName, $MaximumSizeInBytes)
    }
}

<#
    .SYNOPSIS
        Sets the desired resource state.

    .PARAMETER LogName
        Specifies the given name of a eventlog.

    .PARAMETER LogMode
        Specifies the given LogMode for a specified eventlog.
#>
Function Set-LogMode
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.String]
        $LogName,

        [Parameter()]
        [ValidateSet('AutoBackup','Circular','Retain')]
        [System.String]
        $LogMode,

        [Parameter()]
        [System.Int32]
        $LogRetentionDays,

        [Parameter()]
        [System.Int64]
        $MaximumSizeInBytes
    )

    switch ($LogMode)
    {
        'AutoBackup' { $LogModeLimit = 'OverwriteOlder' }
        'Circular' { $LogModeLimit = 'OverwriteAsNeeded' }
        'Retain' { $LogModeLimit = 'DoNotOverWrite' }
    }

    Write-Verbose -Message ($localizedData.SettingEventlogLogMode -f $LogName, $LogModeLimit)

    if ($Logmode -ne 'AutoBackup')
    {
        try
        {
            Limit-Eventlog -LogName $LogName -OverflowAction $LogModeLimit -MaximumSize $MaximumSizeInBytes -Verbose
            Write-Verbose -Message ($localizedData.SettingWinEventlogLogModeSuccess -f $LogName, $LogMode)
        }
        catch
        {
            Write-Verbose -Message ($localizedData.SettingWinEventlogLogModeFailed -f $LogName, $LogMode)
        }
    }
    else
    {
        try
        {
            Limit-Eventlog -LogName $LogName -OverflowAction $LogModeLimit -RetentionDays $LogRetentionDays -Verbose
            Write-Verbose -Message ($localizedData.SettingWinEventlogLogModeSuccess -f $LogName, $LogMode)
        }
        catch
        {
            Write-Verbose -Message ($localizedData.SettingWinEventlogLogModeFailed -f $LogName, $LogMode)
        }
    }
}

<#
    .SYNOPSIS
        Sets the desired resource state.

    .PARAMETER LogName
        Specifies the given name of a eventlog.

    .PARAMETER SecurityDescriptor
        Specifies the given SecurityDescriptor for a specified eventlog.
#>
Function Set-SecurityDescriptor
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.String]
        $LogName,

        [Parameter()]
        [System.String]
        $SecurityDescriptor
    )

    $log = Get-WinEvent -ListLog $LogName
    $log.SecurityDescriptor = $SecurityDescriptor
    Write-Verbose -Message ($localizedData.SettingEventlogSecurityDescriptor -f $LogName, $SecurityDescriptor)

    try
    {
        $log.SaveChanges()
        Write-Verbose -Message ($localizedData.SettingWinEventlogSecurityDescriptorSuccess -f $LogName, $SecurityDescriptor)
    }
    catch
    {
        Write-Verbose -Message ($localizedData.SettingWinEventlogSecurityDescriptorFailed -f $LogName, $SecurityDescriptor)
    }
}

<#
    .SYNOPSIS
        Sets the desired resource state.

    .PARAMETER LogName
        Specifies the given name of a eventlog.

    .PARAMETER IsEnabled
        Specifies the given state of a eventlog.
#>
Function Set-IsEnabled
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.String]
        $LogName,

        [Parameter()]
        [System.Boolean]
        $IsEnabled
    )

    $log = Get-WinEvent -ListLog $LogName
    $log.IsEnabled = $IsEnabled
    Write-Verbose -Message ($localizedData.SettingEventlogIsEnabled -f $LogName, $IsEnabled)

    try
    {
        $log.SaveChanges()
        Write-Verbose -Message ($localizedData.SettingWinEventlogIsEnabledSuccess -f $LogName, $IsEnabled)
    }
    catch
    {
        Write-Verbose -Message ($localizedData.SettingWinEventlogIsEnabledFailed -f $LogName, $IsEnabled)
    }
}

<#
    .SYNOPSIS
        Sets the desired resource state.

    .PARAMETER LogName
        Specifies the given name of a eventlog.

    .PARAMETER LogFilePath
        Specifies the given LogFilepath of a eventlog.
#>
Function Set-LogFilePath
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [System.String]
        $LogName,

        [Parameter()]
        [System.String]
        $LogFilePath
    )

    $log = Get-WinEvent -ListLog $LogName
    $log.LogFilePath = $LogFilePath
    Write-Verbose -Message ($localizedData.SettingEventlogLogFilePath -f $LogName, $LogFilePath)

    try
    {
        $log.SaveChanges()
        Write-Verbose -Message ($localizedData.SettingWinEventlogLogFilePathSuccess -f $LogName, $LogFilePath)
    }
    catch
    {
        Write-Verbose -Message ($localizedData.SettingWinEventlogLogFilePathFailed -f $LogName, $LogFilePath)
    }
}

Export-ModuleMember -Function *-TargetResource
