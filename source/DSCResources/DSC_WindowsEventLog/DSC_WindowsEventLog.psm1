$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    .SYNOPSIS
        Gets the current state of an event log.

    .PARAMETER LogName
        Specifies the name of a valid event log.
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

    Write-Verbose -Message ($script:localizedData.GetTargetResource -f $LogName)

    $log = Get-WindowsEventLog -LogName $LogName

    if ($log.IsClassicLog -eq $true)
    {
        $logRetentionDays = Get-WindowsEventLogRetentionDays -LogName $LogName
    }

    $restrictGuestAccess = Get-WindowsEventLogRestrictGuestAccess -LogName $LogName

    $returnValue = @{
        LogName             = $LogName
        LogFilePath         = $log.LogFilePath
        MaximumSizeInBytes  = [System.Int64] $log.MaximumSizeInBytes
        IsEnabled           = $log.IsEnabled
        LogMode             = $log.LogMode
        SecurityDescriptor  = $log.SecurityDescriptor
        LogRetentionDays    = $logRetentionDays
        RestrictGuestAccess = $restrictGuestAccess
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the desired state of an event log.

    .PARAMETER LogName
        Specifies the name of a valid event log.

    .PARAMETER MaximumSizeInBytes
        Specifies the maximum size in bytes for the specified event log.

    .PARAMETER LogMode
        Specifies the log mode for the specified event log.

    .PARAMETER LogRetentionDays
        Specifies the number of days to retain events when the log mode is AutoBackup.

    .PARAMETER SecurityDescriptor
        Specifies the SDDL for the specified event log.

    .PARAMETER IsEnabled
        Specifies whether the specified event log should be enabled or disabled.

    .PARAMETER LogFilePath
        Specifies the file name and path for the specified event log.

    .PARAMETER RegisteredSource
        Specifies the name of an event source to register for the specified event log.

    .PARAMETER CategoryResourceFile
        Specifies the category resource file for the event source.

    .PARAMETER MessageResourceFile
        Specifies the message resource file for the event source.

    .PARAMETER ParameterResourceFile
        Specifies the parameter resource file for the event source.

    .PARAMETER RestrictGuestAccess
        Specifies whether to allow guests to have access to the specified event log.
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
        [ValidateRange(64KB, 4GB)]
        [System.Int64]
        $MaximumSizeInBytes,

        [Parameter()]
        [ValidateSet('AutoBackup', 'Circular', 'Retain')]
        [System.String]
        $LogMode,

        [Parameter()]
        [System.Int32]
        [ValidateRange(0, 365)]
        $LogRetentionDays,

        [Parameter()]
        [System.String]
        $SecurityDescriptor,

        [Parameter()]
        [System.String]
        $LogFilePath,

        [Parameter()]
        [System.String]
        $RegisteredSource,

        [Parameter()]
        [System.String]
        $CategoryResourceFile,

        [Parameter()]
        [System.String]
        $MessageResourceFile,

        [Parameter()]
        [System.String]
        $ParameterResourceFile,

        [Parameter()]
        [System.Boolean]
        $RestrictGuestAccess
    )

    $shouldSaveLogFile = $false
    $shouldRegisterSource = $false
    $log = Get-WindowsEventLog -LogName $LogName
    $currentRestrictGuestAccess = Get-WindowsEventLogRestrictGuestAccess -LogName $LogName

    if ($PSBoundParameters.ContainsKey('IsEnabled') `
            -and $IsEnabled -ne $log.IsEnabled)
    {
        Write-Verbose -Message ($script:localizedData.SetTargetResourceProperty `
                -f $LogName, 'IsEnabled', $log.IsEnabled, $isEnabled)
        $log.IsEnabled = $IsEnabled
        $shouldSaveLogFile = $true
    }

    if ($PSBoundParameters.ContainsKey('MaximumSizeInBytes') `
            -and $MaximumSizeInBytes -ne $log.MaximumSizeInBytes)
    {
        Write-Verbose -Message ($script:localizedData.SetTargetResourceProperty `
                -f $LogName, 'MaximumSizeInBytes', $log.MaximumSizeInBytes, $MaximumSizeInBytes)
        $log.MaximumSizeInBytes = $MaximumSizeInBytes
        $shouldSaveLogFile = $true
    }

    if ($PSBoundParameters.ContainsKey('LogMode') `
            -and $LogMode -ne $log.LogMode)
    {
        Write-Verbose -Message ($script:localizedData.SetTargetResourceProperty `
                -f $LogName, 'LogMode', $log.LogMode, $LogMode)
        $log.LogMode = $LogMode
        $shouldSaveLogFile = $true
    }

    if ($PSBoundParameters.ContainsKey('SecurityDescriptor') `
            -and $SecurityDescriptor -ne $log.SecurityDescriptor)
    {
        Write-Verbose -Message ($script:localizedData.SetTargetResourceProperty `
                -f $LogName, 'SecurityDescriptor', $log.SecurityDescriptor, $SecurityDescriptor)
        $log.SecurityDescriptor = $SecurityDescriptor
        $shouldSaveLogFile = $true
    }

    if ($PSBoundParameters.ContainsKey('LogFilePath') `
            -and $LogFilePath -ne $log.LogFilePath) {
        Write-Verbose -Message ($script:localizedData.SetTargetResourceProperty `
                -f $LogName, 'LogFilePath', $log.LogFilePath, $LogFilePath)
        $log.LogFilePath = $LogFilePath
        $shouldSaveLogFile = $true
    }

    if ($PSBoundParameters.ContainsKey('RestrictGuestAccess') `
            -and $RestrictGuestAccess -ne $currentRestrictGuestAccess)
    {
        Write-Verbose -Message ($script:localizedData.SetTargetResourceProperty `
                -f $LogName, 'RestrictGuestAccess', $currentRestrictGuestAccess, $RestrictGuestAccess)

        if ($PSBoundParameters.ContainsKey('SecurityDescriptor'))
        {
            Write-Warning -Message ($script:localizedData.ModifyUserProvidedSecurityDescriptor)
            $log.SecurityDescriptor = Set-WindowsEventLogRestrictGuestAccess `
                -LogName $LogName -RestrictGuestAccess $RestrictGuestAccess -Sddl $SecurityDescriptor
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.ModifySystemProvidedSecurityDescriptor)
            $log.SecurityDescriptor = Set-WindowsEventLogRestrictGuestAccess `
                -LogName $LogName -RestrictGuestAccess $RestrictGuestAccess -Sddl $log.SecurityDescriptor
        }

        $shouldSaveLogFile = $true
    }

    if ($PSBoundParameters.ContainsKey('RegisteredSource'))
    {
        $sourceProperties = @{
            LogName    = $LogName
            SourceName = $RegisteredSource
        }

        $currentRegisteredSource = Get-WindowsEventLogRegisteredSource `
            -LogName $LogName `
            -SourceName $RegisteredSource

        $currentCategoryResourceFile = Get-WindowsEventLogRegisteredSourceFile `
            -LogName $LogName `
            -SourceName $RegisteredSource `
            -ResourceFileType Category

        $currentMessageResourceFile = Get-WindowsEventLogRegisteredSourceFile `
            -LogName $LogName `
            -SourceName $RegisteredSource `
            -ResourceFileType Message

        $currentParameterResourceFile = Get-WindowsEventLogRegisteredSourceFile `
            -LogName $LogName `
            -SourceName $RegisteredSource `
            -ResourceFileType Parameter

        if ($RegisteredSource -ne $currentRegisteredSource)
        {
            Write-Verbose -Message ($script:localizedData.SetTargetResourceProperty `
                    -f $LogName, 'RegisteredSource', $currentRegisteredSource, $RegisteredSource)
            $shouldRegisterSource = $true
        }

        if ($PSBoundParameters.ContainsKey('CategoryResourceFile') `
                -and $CategoryResourceFile -ne $currentCategoryResourceFile)
        {
            Write-Verbose -Message ($script:localizedData.SetTargetResourceProperty `
                    -f $LogName, 'CategoryResourceFile', $currentCategoryResourceFile, $CategoryResourceFile)
            $sourceProperties.CategoryResourceFile = $CategoryResourceFile
            $shouldRegisterSource = $true
        }

        if ($PSBoundParameters.ContainsKey('MessageResourceFile') `
                -and $MessageResourceFile -ne $currentMessageResourceFile)
        {
            Write-Verbose -Message ($script:localizedData.SetTargetResourceProperty `
                    -f $LogName, 'MessageResourceFile', $currentMessageResourceFile, $MessageResourceFile)
            $sourceProperties.MessageResourceFile = $MessageResourceFile
            $shouldRegisterSource = $true
        }

        if ($PSBoundParameters.ContainsKey('ParameterResourceFile') `
                -and $ParameterResourceFile -ne $currentParameterResourceFile)
        {
            Write-Verbose -Message ($script:localizedData.SetTargetResourceProperty `
                    -f $LogName, 'ParameterResourceFile', $currentParameterResourceFile, $ParameterResourceFile)
            $sourceProperties.ParameterResourceFile = $ParameterResourceFile
            $shouldRegisterSource = $true
        }
    }

    if ($shouldSaveLogFile)
    {
        Save-WindowsEventLog -Log $log
    }

    if ($shouldRegisterSource)
    {
        Register-WindowsEventLogSource @sourceProperties
    }

    if ($PSBoundParameters.ContainsKey('LogRetentionDays'))
    {
        if ($log.IsClassicLog -eq $true)
        {
            Set-WindowsEventLogRetentionDays -LogName $LogName -LogMode $LogMode -LogRetentionDays $LogRetentionDays
        }
        else
        {
            Write-Warning -Message ($script:localizedData.SetWindowsEventLogRetentionDaysNotClassic -f $LogName)
        }
    }
}

<#
    .SYNOPSIS
        Tests if the current state of an event log is the same as the desired state.

    .PARAMETER LogName
        Specifies the name of a valid event log.

    .PARAMETER MaximumSizeInBytes
        Specifies the maximum size in bytes for the specified event log.

    .PARAMETER LogMode
        Specifies the log mode for the specified event log.

    .PARAMETER LogRetentionDays
        Specifies the number of days to retain events when the log mode is AutoBackup.

    .PARAMETER SecurityDescriptor
        Specifies the SDDL for the specified event log.

    .PARAMETER IsEnabled
        Specifies whether the specified event log should be enabled or disabled.

    .PARAMETER LogFilePath
        Specifies the file name and path for the specified event log.

    .PARAMETER RegisteredSource
        Specifies the name of an event source in the specified event log.

    .PARAMETER CategoryResourceFile
        Specifies the category resource file for the event source.

    .PARAMETER MessageResourceFile
        Specifies the message resource file for the event source.

    .PARAMETER ParameterResourceFile
        Specifies the parameter resource file for the event source.
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
        [ValidateRange(64KB, 4GB)]
        [System.Int64]
        $MaximumSizeInBytes,

        [Parameter()]
        [ValidateSet('AutoBackup', 'Circular', 'Retain')]
        [System.String]
        $LogMode,

        [Parameter()]
        [ValidateRange(0, 365)]
        [System.Int32]
        $LogRetentionDays,

        [Parameter()]
        [System.String]
        $SecurityDescriptor,

        [Parameter()]
        [System.String]
        $LogFilePath,

        [Parameter()]
        [System.String]
        $RegisteredSource,

        [Parameter()]
        [System.String]
        $CategoryResourceFile,

        [Parameter()]
        [System.String]
        $MessageResourceFile,

        [Parameter()]
        [System.String]
        $ParameterResourceFile,

        [Parameter()]
        [System.Boolean]
        $RestrictGuestAccess
    )

    $inDesiredState = $true
    $log = Get-WindowsEventLog -LogName $LogName

    if ($log.IsClassicLog -eq $true)
    {
        $currentLogRetentionDays = Get-WindowsEventLogRetentionDays -LogName $LogName
    }

    $currentRestrictGuestAccess = Get-WindowsEventLogRestrictGuestAccess -LogName $LogName

    if ($PSBoundParameters.ContainsKey('IsEnabled') `
            -and $IsEnabled -ne $log.IsEnabled)
    {
        Write-Verbose -Message ($script:localizedData.TestTargetResourcePropertyNotInDesiredState `
                -f $LogName, 'IsEnabled', $log.IsEnabled, $IsEnabled)
        $inDesiredState = $false
    }

    if ($PSBoundParameters.ContainsKey('MaximumSizeInBytes') `
            -and $MaximumSizeInBytes -ne $log.MaximumSizeInBytes)
    {
        Write-Verbose -Message ($script:localizedData.TestTargetResourcePropertyNotInDesiredState `
                -f $LogName, 'MaximumSizeInBytes', $log.MaximumSizeInBytes, $MaximumSizeInBytes)
        $inDesiredState = $false
    }

    if ($PSBoundParameters.ContainsKey('LogMode') `
            -and $LogMode -ne $log.LogMode)
    {
        Write-Verbose -Message ($script:localizedData.TestTargetResourcePropertyNotInDesiredState `
                -f $LogName, 'LogMode', $log.LogMode, $LogMode)
        $inDesiredState = $false
    }

    if ($PSBoundParameters.ContainsKey('SecurityDescriptor') `
            -and $SecurityDescriptor -ne $log.SecurityDescriptor)
    {
        Write-Verbose -Message ($script:localizedData.TestTargetResourcePropertyNotInDesiredState `
                -f $LogName, 'SecurityDescriptor', $log.SecurityDescriptor, $SecurityDescriptor)
        $inDesiredState = $false
    }

    if ($PSBoundParameters.ContainsKey('LogFilePath') `
            -and $LogFilePath -ne $log.LogFilePath)
    {
        Write-Verbose -Message ($script:localizedData.TestTargetResourcePropertyNotInDesiredState `
                -f $LogName, 'LogFilePath', $log.LogFilePath, $LogFilePath)
        $inDesiredState = $false
    }

    if ($PSBoundParameters.ContainsKey('RestrictGuestAccess') `
            -and $RestrictGuestAccess -ne $currentRestrictGuestAccess)
    {
        Write-Verbose -Message ($script:localizedData.TestTargetResourcePropertyNotInDesiredState `
                -f $LogName, 'RestrictGuestAccess', $currentRestrictGuestAccess, $RestrictGuestAccess)
        $inDesiredState = $false
    }

    if ($PSBoundParameters.ContainsKey('RegisteredSource'))
    {
        $currentRegisteredSource = Get-WindowsEventLogRegisteredSource `
            -LogName $LogName `
            -SourceName $RegisteredSource

        $currentCategoryResourceFile = Get-WindowsEventLogRegisteredSourceFile `
            -LogName $LogName `
            -SourceName $RegisteredSource `
            -ResourceFileType Category

        $currentMessageResourceFile = Get-WindowsEventLogRegisteredSourceFile `
            -LogName $LogName `
            -SourceName $RegisteredSource `
            -ResourceFileType Message

        $currentParameterResourceFile = Get-WindowsEventLogRegisteredSourceFile `
            -LogName $LogName `
            -SourceName $RegisteredSource `
            -ResourceFileType Parameter

        if ($RegisteredSource -ne $currentRegisteredSource)
        {
            Write-Verbose -Message ($script:localizedData.TestTargetResourcePropertyNotInDesiredState `
                    -f $LogName, 'RegisteredSource', $currentRegisteredSource, $RegisteredSource)
            $inDesiredState = $false
        }

        if ($PSBoundParameters.ContainsKey('CategoryResourceFile') `
                -and $CategoryResourceFile -ne $currentCategoryResourceFile)
        {
            Write-Verbose -Message ($script:localizedData.TestTargetResourcePropertyNotInDesiredState `
                    -f $LogName, 'CategoryResourceFile', $currentCategoryResourceFile, $CategoryResourceFile)
            $inDesiredState = $false
        }

        if ($PSBoundParameters.ContainsKey('MessageResourceFile') `
                -and $MessageResourceFile -ne $currentMessageResourceFile)
        {
            Write-Verbose -Message ($script:localizedData.TestTargetResourcePropertyNotInDesiredState `
                    -f $LogName, 'MessageResourceFile', $currentMessageResourceFile, $MessageResourceFile)
            $inDesiredState = $false
        }

        if ($PSBoundParameters.ContainsKey('ParameterResourceFile') `
                -and $ParameterResourceFile -ne $currentParameterResourceFile)
        {
            Write-Verbose -Message ($script:localizedData.TestTargetResourcePropertyNotInDesiredState `
                    -f $LogName, 'ParameterResourceFile', $currentParameterResourceFile, $ParameterResourceFile)
            $inDesiredState = $false
        }
    }

    if ($PSBoundParameters.ContainsKey('LogRetentionDays'))
    {
        if ($log.IsClassicLog -eq $true -and $LogRetentionDays -ne $currentLogRetentionDays)
        {
            Write-Verbose -Message ($script:localizedData.TestTargetResourcePropertyNotInDesiredState `
                    -f $LogName, 'LogRetentionDays', $currentLogRetentionDays, $LogRetentionDays)
            $inDesiredState = $false
        }
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Gets the requested event log and throws an exception if it doesn't exist.

    .PARAMETER LogName
        Specifies the name of a valid event log.
#>
function Get-WindowsEventLog
{
    [CmdletBinding()]
    [OutputType([System.Diagnostics.Eventing.Reader.EventLogConfiguration])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName
    )

    try
    {
        $log = Get-WinEvent -ListLog $LogName -ErrorAction Stop
    }
    catch
    {
        $message = $script:localizedData.GetWindowsEventLogFailure -f $LogName
        New-InvalidOperationException -Message $message -ErrorRecord $_
    }

    return $log
}

<#
    .SYNOPSIS
        Gets the registered event source for an event log.

    .PARAMETER LogName
        Specifies the name of a valid event log.

    .PARAMETER SourceName
        Specifies the specific event source to retrieve.
#>
function Get-WindowsEventLogRegisteredSource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SourceName
    )

    $source = ''
    $logEventSources = Get-CimInstance -Class Win32_NTEventLogFile |
        Where-Object -Property LogfileName -EQ $LogName |
        Select-Object -ExpandProperty Sources

    if ($logEventSources -contains $SourceName)
    {
        $source = $SourceName
    }

    return $source
}

<#
    .SYNOPSIS
        Gets the full path of a registered event source.

    .PARAMETER LogName
        Specifies the name of a valid event log.

    .PARAMETER SourceName
        Specifies the specific event source.

    .PARAMETER ResourceFileType
        Specifies the resource file type to retrieve.
#>
function Get-WindowsEventLogRegisteredSourceFile
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [System.String]
        $SourceName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Category', 'Message', 'Parameter')]
        [System.String]
        $ResourceFileType
    )

    $file = ''

    if ($SourceName -ne '')
    {
        $source = Get-ItemProperty `
            -Path "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\$LogName\$SourceName" `
            -ErrorAction SilentlyContinue

        switch ($ResourceFileType)
        {
            'Category' {
                if ($null -ne $source.CategoryMessageFile)
                {
                    $file = $source.CategoryMessageFile
                }
            }

            'Message' {
                if ($null -ne $source.EventMessageFile)
                {
                    $file = $source.EventMessageFile
                }
            }

            'Parameter' {
                if ($null -ne $Source.ParameterMessageFile)
                {
                    $file = $source.ParameterMessageFile
                }
            }
        }
    }

    return $file
}

<#
    .SYNOPSIS
        Gets the status of guest access for an event log.

    .PARAMETER LogName
        Specifies the name of a valid event log.
#>
function Get-WindowsEventLogRestrictGuestAccess
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName
    )

    $eventLogRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\EventLog'
    $logRegistryPath = Join-Path -Path $eventLogRegistryPath -ChildPath $LogName

    try
    {
        $logProperties = Get-ItemProperty -Path $logRegistryPath -ErrorAction Stop
    }
    catch
    {
        return $false
    }

    return ($logProperties.RestrictGuestAccess -eq 1)
}

<#
    .SYNOPSIS
        Gets the retention for an event log and throws an exception if a problem occurs.

    .PARAMETER LogName
        Specifies the name of a valid event log.
#>
function Get-WindowsEventLogRetentionDays
{
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName
    )

    $matchingEventLog = Get-EventLog -List |
        Where-Object -Property Log -EQ $LogName -ErrorAction Stop

    if ($null -eq $matchingEventLog.MinimumRetentionDays)
    {
        $message = $script:localizedData.GetWindowsEventLogRetentionDaysFailure -f $LogName
        New-InvalidArgumentException -Message $message -ArgumentName 'LogName'
    }

    return $matchingEventLog.MinimumRetentionDays
}

<#
    .SYNOPSIS
        Registers an event source and throws an exception if the file path is invalid or registration fails.

    .PARAMETER LogName
        Specifies the name of a valid event log.

    .PARAMETER SourceName
        Specifies the custom source to add to the Windows Event Log.

    .PARAMETER CategoryResourceFile
        Specifies the category resource file to register.

    .PARAMETER MessageResourceFile
        Specifies the message resource file to register.

    .PARAMETER ParameterResourceFile
        Specifies the parameter resource file to register.
#>
function Register-WindowsEventLogSource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $SourceName,

        [Parameter()]
        [System.String]
        $CategoryResourceFile,

        [Parameter()]
        [System.String]
        $MessageResourceFile,

        [Parameter()]
        [System.String]
        $ParameterResourceFile
    )

    $arguments = @{
        LogName = $LogName
        Source  = $SourceName
    }

    if ($PSBoundParameters.ContainsKey('CategoryResourceFile'))
    {
        if (-not [System.String]::IsNullOrEmpty($CategoryResourceFile) -and `
            -not (Test-Path -Path $CategoryResourceFile -IsValid))
        {
            $message = $script:localizedData.RegisterWindowsEventLogSourceInvalidPath `
                -f $SourceName, $CategoryResourceFile
            New-InvalidArgumentException -Message $message -ArgumentName 'CategoryResourceFile'
        }

        $arguments.CategoryResourceFile = $CategoryResourceFile
    }

    if ($PSBoundParameters.ContainsKey('MessageResourceFile'))
    {
        if (-not [System.String]::IsNullOrEmpty($MessageResourceFile) -and `
            -not (Test-Path -Path $MessageResourceFile -IsValid))
        {
            $message = $script:localizedData.RegisterWindowsEventLogSourceInvalidPath `
                -f $SourceName, $MessageResourceFile
            New-InvalidArgumentException -Message $message -ArgumentName 'MessageResourceFile'
        }

        $arguments.MessageResourceFile = $MessageResourceFile
    }

    if ($PSBoundParameters.ContainsKey('ParameterResourceFile'))
    {
        if (-not [System.String]::IsNullOrEmpty($ParameterResourceFile) -and `
            -not (Test-Path -Path $ParameterResourceFile -IsValid))
        {
            $message = $script:localizedData.RegisterWindowsEventLogSourceInvalidPath `
                -f $SourceName, $ParameterResourceFile
            New-InvalidArgumentException -Message $message -ArgumentName 'ParameterResourceFile'
        }

        $arguments.ParameterResourceFile = $ParameterResourceFile
    }

    try
    {
        if ((Get-WindowsEventLogRegisteredSource -LogName $LogName -SourceName $SourceName) -eq '')
        {
            New-EventLog @arguments -ErrorAction Stop
        }
        else
        {
            Remove-EventLog -Source $SourceName -ErrorAction Stop
            New-EventLog @arguments -ErrorAction Stop
        }
    }
    catch
    {
        $message = $script:localizedData.RegisterWindowsEventLogSourceFailure -f $LogName, $RegisteredSource
        New-InvalidOperationException -Message $message -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Saves changes to an event log and throws an exception if the operation fails.

    .PARAMETER Log
        Specifies the given object of a Windows Event Log.
#>
function Save-WindowsEventLog
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.Eventing.Reader.EventLogConfiguration]
        $log
    )

    try
    {
        $log.SaveChanges()
    }
    catch
    {
        $message = $script:localizedData.SaveWindowsEventLogFailure -f $LogName
        New-InvalidOperationException -Message $message -ErrorRecord $_
    }
}

<#
    .SYNOPSIS
        Sets the status of guest access for an event log and throws an exception if the operation fails.

    .PARAMETER LogName
        Specifies the name of a valid event log.

    .PARAMETER RestrictGuestAccess
        Specifies whether to enable or disable guest access.

    .PARAMETER Sddl
        Specifies the SDDL to update.
#>
function Set-WindowsEventLogRestrictGuestAccess
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $RestrictGuestAccess,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Sddl
    )

    $eventLogRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\EventLog'
    $logRegistryPath = Join-Path -Path $eventLogRegistryPath -ChildPath $LogName

    try
    {
        Set-ItemProperty -Path $logRegistryPath `
            -Name 'RestrictGuestAccess' -Value $RestrictGuestAccess -ErrorAction Stop
    }
    catch
    {
        $message = $script:localizedData.SetWindowsEventLogRestrictGuestAccessFailure -f $LogName
        New-InvalidOperationException -Message $message -ErrorRecord $_
    }

    $logSddl = ''
    $sddlDescriptors = $Sddl.Replace(":", ":`n").Replace(")", ")`n").Split()

    foreach ($sddlDescriptor in $sddlDescriptors)
    {
        if ($sddlDescriptor -notmatch 'BG\)$')
        {
            $logSddl += $sddlDescriptor
        }
    }

    if ($RestrictGuestAccess -eq $false)
    {
        $logSddl += '(A;;0x1;;;BG)'
    }

    return $logSddl
}

<#
    .SYNOPSIS
        Sets retention for an event log and throws an exception if the operation fails.

    .PARAMETER LogName
        Specifies the name of a valid event log.

    .PARAMETER LogMode
        Specifies the log mode for the specified event log.

    .PARAMETER LogRetentionDays
        Specifies the number of days to retain events when the log mode is AutoBackup.
#>
function Set-WindowsEventLogRetentionDays
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $LogMode,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $LogRetentionDays
    )

    if ($LogMode -eq 'AutoBackup')
    {
        try
        {
            $matchingEventLog = Get-EventLog -List | Where-Object -Property Log -EQ $LogName -ErrorAction Stop
        }
        catch
        {
            $message = $script:localizedData.GetWindowsEventLogRetentionDaysFailure -f $LogName
            New-InvalidOperationException -Message $message -ErrorRecord $_
        }

        $minimumRetentionDaysForLog = $matchingEventLog.MinimumRetentionDays

        if ($LogRetentionDays -ne $minimumRetentionDaysForLog)
        {
            try
            {
                Limit-EventLog -LogName $LogName `
                    -OverflowAction 'OverwriteOlder' `
                    -RetentionDays $LogRetentionDays `
                    -ErrorAction Stop
            }
            catch
            {
                $message = $script:localizedData.SetWindowsEventLogRetentionDaysFailure -f $LogName
                New-InvalidOperationException -Message $message -ErrorRecord $_
            }
        }
    }
    else
    {
        $message = $script:localizedData.SetWindowsEventLogRetentionDaysWrongMode -f $LogName
        New-InvalidArgumentException -Message $message -ArgumentName 'LogMode'
    }
}

Export-ModuleMember -Function *-TargetResource
