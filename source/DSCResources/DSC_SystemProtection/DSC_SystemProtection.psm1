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
        Gets the current system protection state.

    .PARAMETER Ensure
        Specifies the desired state of the resource.

    .PARAMETER DriveLetter
        Specifies the drive letter to get.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-Za-z]$')]
        [System.String]
        $DriveLetter
    )
`
    $returnValue = @{
        Ensure = 'Absent'
    }

    $productType = (Get-CimInstance -ClassName Win32_OperatingSystem).ProductType

    if ($productType -eq 1)
    {
        Write-Verbose -Message ($script:localizedData.FoundWorkstationOS -f $productType)

        $systemProtectionState = Get-SystemProtectionState
        Write-Verbose -Message ($script:localizedData.SystemProtectionState -f $systemProtectionState)

        if ($systemProtectionState -eq 'Present')
        {
            $enabledDrives = Get-SppRegistryValue

            if ($null -eq $enabledDrives)
            {
                $message = $script:localizedData.GetEnabledDrivesFailure
                New-InvalidOperationException -Message $message
            }

            foreach ($drive in $enabledDrives)
            {
                $currentDriveLetter = ConvertTo-DriveLetter -Drive $drive
                if ($currentDriveLetter -eq $DriveLetter)
                {
                    $maxPercent = Get-DiskUsageConfiguration -Drive $drive
                    Write-Verbose -Message ($script:localizedData.DriveFound -f $currentDriveLetter, $maxPercent)
                    break
                }
                else
                {
                    Write-Verbose -Message ($script:localizedData.DriveSkipped -f $currentDriveLetter)
                }
            }
        }

        $returnValue = @{
            Ensure      = $systemProtectionState
            DriveLetter = $currentDriveLetter
            DiskUsage   = $maxPercent
        }
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.FoundServerOS -f $productType)
        Write-Warning -Message $script:localizedData.NotWorkstationOS
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the desired system protection state for a drive.

    .PARAMETER Ensure
        Indicates whether system protection should be enabled or disabled.

    .PARAMETER DriveLetter
        Specifies the drive letter to be configured.

    .PARAMETER DiskUsage
        Specifies the maximum disk space to use for protection as a percentage.

    .PARAMETER Force
        If a resize operation fails, force the deletion of all checkpoints.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-Za-z]$')]
        [System.String]
        $DriveLetter,

        [Parameter()]
        [ValidateRange(1,100)]
        [System.Int32]
        $DiskUsage,

        [Parameter()]
        [System.Boolean]
        $Force = $false
    )

    $productType = (Get-CimInstance -ClassName Win32_OperatingSystem).ProductType

    if ($productType -ne 1)
    {
        Write-Verbose -Message ($script:localizedData.FoundServerOS -f $productType)
        $message = $script:localizedData.NotWorkstationOS
        New-InvalidOperationException -Message $message
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.FoundWorkstationOS -f $productType)
    }

    switch ($Ensure)
    {
        'Present'
        {
            try
            {
                Enable-ComputerRestore -Drive ($DriveLetter + ':') -ErrorAction Stop
            }
            catch
            {
                $message = ($script:localizedData.EnableComputerRestoreFailure -f $DriveLetter)
                New-InvalidOperationException -Message $message
            }

            Write-Verbose -Message ($script:localizedData.EnableComputerRestoreSuccess -f $DriveLetter)

            if ($PSBoundParameters.ContainsKey('DiskUsage'))
            {
                $process = Invoke-VssAdmin `
                    -Operation Resize -Drive ($DriveLetter + ':') -DiskUsage $DiskUsage

                Write-Verbose -Message ($script:localizedData.VssAdminReturnValues -f $process.ExitCode, 'Resize', $Force)

                if ($process.ExitCode -ne 0 -and $Force -eq $true)
                {
                    Write-Warning `
                        -Message ($script:localizedData.VssShadowResizeFailureWithForce -f $DriveLetter)

                    $process = Invoke-VssAdmin -Operation Delete -Drive ($DriveLetter + ':')

                    Write-Verbose -Message ($script:localizedData.VssAdminReturnValues -f $process.ExitCode, 'Delete', $Force)

                    if ($process.ExitCode -ne 0)
                    {
                        $message = ($script:localizedData.VssShadowDeleteFailure -f $DriveLetter)
                        New-InvalidOperationException -Message $message
                    }
                    else
                    {
                        $process = Invoke-VssAdmin `
                            -Operation Resize -Drive ($DriveLetter + ':') -DiskUsage $DiskUsage

                        Write-Verbose -Message ($script:localizedData.VssAdminReturnValues -f $process.ExitCode, 'Resize', $Force)

                        if ($process.ExitCode -ne 0)
                        {
                            $message = ($script:localizedData.VssShadowResizeFailureWithForce2 -f $DriveLetter)
                            New-InvalidOperationException -Message $message
                        }
                    }
                }
                elseif ($process.ExitCode -ne 0)
                {
                    Write-Verbose -Message ($script:localizedData.VssAdminReturnValues -f $process.ExitCode, 'Resize', $Force)

                    $message = ($script:localizedData.VssShadowResizeFailure -f $DriveLetter)
                    New-InvalidOperationException -Message $message
                }
                else
                {
                    Write-Verbose -Message ($script:localizedData.VssShadowResizeSuccess -f $DriveLetter)
                }
            }
        }

        'Absent'
        {
            try
            {
                Disable-ComputerRestore -Drive ($DriveLetter + ':') -ErrorAction Stop
            }
            catch
            {
                $message = ($script:localizedData.DisableComputerRestoreFailure -f $DriveLetter)
                New-InvalidOperationException -Message $message
            }

            Write-Verbose -Message ($script:localizedData.DisableComputerRestoreSuccess -f $DriveLetter)
        }
    }
}

<#
    .SYNOPSIS
        Tests if the current drive protection state is the same as the desired state.

    .PARAMETER Ensure
        Indicates whether system protection should be enabled or disabled.

    .PARAMETER DriveLetter
        Specifies the drive letter to be tested.

    .PARAMETER DiskUsage
        Specifies the maximum disk space to use for protection as a percentage.

    .PARAMETER Force
        If a resize operation fails, force the deletion of all checkpoints.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-Za-z]$')]
        [System.String]
        $DriveLetter,

        [Parameter()]
        [ValidateRange(1,100)]
        [System.Int32]
        $DiskUsage,

        [Parameter()]
        [System.Boolean]
        $Force = $false
    )

    $productType = (Get-CimInstance -ClassName Win32_OperatingSystem).ProductType

    if ($productType -eq 1)
    {
        $enabledDrives = @()
        $registryDrives = Get-SppRegistryValue

        foreach ($drive in $registryDrives)
        {
            $enabledDrives += ConvertTo-DriveLetter -Drive $drive
        }

        $foundDrive            = $false
        $currentEnabledDrives  = Get-SppRegistryValue

        foreach ($drive in $currentEnabledDrives)
        {
            $currentDriveLetter = ConvertTo-DriveLetter -Drive $drive

            if ($currentDriveLetter -eq $DriveLetter)
            {
                $foundDrive = $true
                $maxPercent = Get-DiskUsageConfiguration -Drive $drive
                Write-Verbose -Message ($script:localizedData.DriveFound -f $currentDriveLetter, $maxPercent)
                break
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.DriveSkipped -f $currentDriveLetter)
            }
        }

        if ($Ensure -eq 'Present')
        {
            $inDesiredState = $foundDrive
        }
        else
        {
            $inDesiredState = -not $foundDrive
        }

        Write-Verbose -Message ($script:localizedData.InDesiredStateDriveLetter -f $currentDriveLetter)

        if ($PSBoundParameters.ContainsKey('DiskUsage') -and $foundDrive -and $DiskUsage -ne $maxPercent)
        {
            $inDesiredState = $false
            Write-Verbose -Message ($script:localizedData.InDesiredStateDiskUsageFalse -f $currentDriveLetter)
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.InDesiredStateDiskUsageUnchanged -f $currentDriveLetter)
        }
    }
    else
    {
        Write-Warning -Message $script:localizedData.NotWorkstationOS
        Write-Warning -Message $script:localizedData.ReturningTrueToBeSafe
        $inDesiredState = $true
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Converts an SPP registry entry into a drive letter.

    .PARAMETER Drive
        Specifies the SPP query to parse.
#>
function ConvertTo-DriveLetter
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Drive
    )

    $driveLetter = $Drive |
        Select-String -Pattern '\w%3A' |
        Select-Object -ExpandProperty Matches |
        Select-Object -ExpandProperty Value

    return $driveLetter -replace '%3A', ''
}

<#
    .SYNOPSIS
        Calculates the maximum configured disk usage for a protected drive.

    .PARAMETER Drive
        Specifies the SPP query to calculate the percentage from.
#>
function Get-DiskUsageConfiguration
{
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Drive
    )

    try
    {
        $vssStorage = Get-CimInstance -ClassName 'Win32_ShadowStorage' -ErrorAction Stop
    }
    catch
    {
        $message = $script:localizedData.UnknownOperatingSystemError
        New-InvalidOperationException -Message $message
    }

    $driveGuid = $Drive |
        Select-String -Pattern '\\\\\?\\Volume{[-0-9A-F]+?}\\' |
        Select-Object -ExpandProperty Matches |
        Select-Object -ExpandProperty Value

    try
    {
        $volumeSize = (Get-Volume -UniqueId $driveGuid -ErrorAction Stop).Size
    }
    catch
    {
        $message = $script:localizedData.UnknownOperatingSystemError
        New-InvalidOperationException -Message $message
    }

    foreach ($instance in $vssStorage)
    {
        if ($driveGuid -eq $instance.Volume.DeviceID)
        {
            $maxPercent = [int]($instance.MaxSpace / $volumeSize * 100)
            break
        }
    }

    return $maxPercent
}

<#
    .SYNOPSIS
        Gets the contents of the SPP registry key.
#>
function Get-SppRegistryValue
{
    $sppRegistryKey  = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SPP\Clients'
    $sppRegistryName = '{09F7EDC5-294E-4180-AF6A-FB0E6A0E9513}'

    if (Get-ItemProperty -Path $sppRegistryKey -Name $sppRegistryName -ErrorAction SilentlyContinue)
    {
        $enabledDrives = Get-ItemPropertyValue `
            -Path $sppRegistryKey `
            -Name $sppRegistryName `
            -ErrorAction SilentlyContinue
    }

    return $enabledDrives
}

<#
    .SYNOPSIS
        Gets the overall system protection state.
#>
function Get-SystemProtectionState
{
    try
    {
        $state = Get-CimInstance -ClassName 'SystemRestoreConfig' -Namespace 'root\DEFAULT' -ErrorAction Stop
    }
    catch
    {
        $message = $script:localizedData.UnknownOperatingSystemError
        New-InvalidOperationException -Message $message
    }

    if ($state.RPSessionInterval -eq 1)
    {
        return 'Present'
    }
    else
    {
        return 'Absent'
    }
}

<#
    .SYNOPSIS
        Invokes vssadmin to change the maximum disk usage.

    .PARAMETER Operation
        Specifies what VSS operation to execute.

    .PARAMETER Drive
        Specifies the drive letter to be configured.

    .PARAMETER DiskUsage
        Specifies the maximum disk space to use for protection as a percentage.
#>
function Invoke-VssAdmin
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Resize', 'Delete')]
        [System.String]
        $Operation,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Drive,

        [Parameter()]
        [System.Int32]
        $DiskUsage
    )

    $ErrorActionPreference = 'Stop'
    $command               = "$env:SystemRoot\System32\vssadmin.exe"
    $resizeArguments       = "Resize ShadowStorage /For=$Drive /On=$Drive /MaxSize=$($DiskUsage)%"
    $deleteArguments       = "Delete Shadows /For=$Drive /quiet"

    switch ($Operation)
    {
        'Resize'
        {
            $arguments = $resizeArguments
        }

        'Delete'
        {
            $arguments = $deleteArguments
        }
    }

    $process                        = New-Object -TypeName System.Diagnostics.ProcessStartInfo
    $process.FileName               = $command
    $process.RedirectStandardError  = $true
    $process.RedirectStandardOutput = $true
    $process.UseShellExecute        = $false
    $process.WindowStyle            = 'Hidden'
    $process.CreateNoWindow         = $true
    $process.Arguments              = $arguments

    $result = Start-VssAdminProcess -Process $process

    return $result
}

<#
    .SYNOPSIS
        Starts the vsssadmin process

    .PARAMETER Process
        Specifies everything neceded to run vssadmin.
#>
function Start-VssAdminProcess
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Diagnostics.ProcessStartInfo]
        $Process
    )

    $p = New-Object -TypeName System.Diagnostics.Process
    $p.StartInfo = $process

    $p.Start() | Out-Null

    $result = @{
        Command   = $command
        Arguments = $arguments
        StdOut    = $p.StandardOutput.ReadToEnd()
        StdErr    = $p.StandardError.ReadToEnd()
        ExitCode  = $p.ExitCode
    }

    $p.WaitForExit()

    return $result
}

Export-ModuleMember -Function *-TargetResource
