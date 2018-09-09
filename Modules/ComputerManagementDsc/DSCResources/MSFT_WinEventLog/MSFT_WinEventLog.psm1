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
        $returnValue = @{
            LogName = [System.String]$LogName
            LogFilePath = [system.String]$log.LogFilePath
            MaximumSizeInBytes = [System.Int64]$log.MaximumSizeInBytes
            IsEnabled = [System.Boolean]$log.IsEnabled
            LogMode = [System.String]$log.LogMode
            SecurityDescriptor = [System.String]$log.SecurityDescriptor
        }

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
        [System.String]
        $SecurityDescriptor,

        [Parameter()]
        [System.String]
        $LogFilePath
    )

    try
    {
        $log = Get-WinEvent -ListLog $logName
        $update = $false

        if ($PSBoundParameters.ContainsKey('MaximumSizeInBytes') -and $MaximumSizeInBytes -ne $log.MaximumSizeInBytes)
        {
            Set-MaximumSizeInBytes -LogName $LogName -MaximumSizeInBytes $MaximumSizeInBytes
            Write-Verbose -Message ($localizedData.SettingEventlogLogSize -f $LogName, $MaximumSizeInBytes)
        }

        if ($PSBoundParameters.ContainsKey('LogMode') -and $LogMode -ne $log.LogMode)
        {
            Set-LogMode -LogName $LogName -LogMode $LogMode
            Write-Verbose -Message ($localizedData.SettingEventlogLogMode -f $LogName, $LogMode)
        }

        if ($PSBoundParameters.ContainsKey('SecurityDescriptor') -and $SecurityDescriptor -ne $log.SecurityDescriptor)
        {
            Set-SecurityDescriptor -LogName $LogName -SecurityDescriptor $SecurityDescriptor
            Write-Verbose -Message ($localizedData.SettingEventlogSecurityDescriptor -f $LogName, $SecurityDescriptor)
        }

        if ($PSBoundParameters.ContainsKey('IsEnabled') -and $IsEnabled -ne $log.IsEnabled)
        {
            Set-IsEnabled -LogName $LogName -IsEnabled $IsEnabled
            Write-Verbose -Message ($localizedData.SettingEventlogIsEnabled -f $LogName, $IsEnabled)
        }

        if ($PSBoundParameters.ContainsKey('LogFilePath') -and $LogFilePath -ne $log.LogFilePath)
        {
            Set-LogFilePath -LogName $LogName -LogFilePath $LogFilePath
            Write-Verbose -Message ($localizedData.SettingEventlogLogFilePath  -f $LogName, $LogFilePath)
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
        [System.String]
        $SecurityDescriptor,

        [Parameter()]
        [System.String]
        $LogFilePath
    )

    try
    {
        $log = Get-WinEvent -ListLog $logName
        if ($PSBoundParameters.ContainsKey('MaximumSizeInBytes') -and $log.MaximumSizeInBytes -ne $MaximumSizeInBytes)
        {
            Write-Verbose -Message ($localizedData.GettingEventlogLogSize -f $LogName, $MaximumSizeInBytes)
            return $false
        }
        if ($PSBoundParameters.ContainsKey('IsEnabled') -and $log.IsEnabled -ne $IsEnabled)
        {
            Write-Verbose -Message ($localizedData.GettingEventlogIsEnabled -f $LogName, $IsEnabled)
            return $false
        }
        if ($PSBoundParameters.ContainsKey('LogMode') -and $log.LogMode -ne $LogMode)
        {
            Write-Verbose -Message ($localizedData.GettingEventlogLogMode -f $LogName, $LogMode)
            return $false
        }
        if ($PSBoundParameters.ContainsKey('SecurityDescriptor') -and $log.SecurityDescriptor -ne $SecurityDescriptor)
        {
            Write-Verbose -Message ($localizedData.GettingEventlogSecurityDescriptor -f $LogName, $SecurityDescriptor)
            return $false
        }
        if ($PSBoundParameters.ContainsKey('LogFilePath') -and $log.LogFilePath -ne $LogFilePath)
        {
            Write-Verbose -Message ($localizedData.GettingEventlogLogFilePath -f $LogName, $LogFilePath)
            return $false
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

    $log = Get-WinEvent -ListLog $logName
    $log.MaximumSizeInBytes = $MaximumSizeInBytes
    $log.SaveChanges()
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
        [System.String]
        $LogMode
    )

    $log = Get-WinEvent -ListLog $LogName
    $log.LogMode = $LogMode
    $log.SaveChanges()
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
    $log.SaveChanges()
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
    $log.SaveChanges()
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
    $log.SaveChanges()
}

Export-ModuleMember -Function *-TargetResource
