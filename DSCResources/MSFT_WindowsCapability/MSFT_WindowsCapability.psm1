$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_WindowsCapability'

<#
    .SYNOPSIS
        Gets the current state of the Windows Capability.

    .PARAMETER Name
        Specifies the given name of a Windows Capability.

    .PARAMETER Ensure
        Specifies whether the Windows Capability should be installed or uninstalled.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.GetTargetResourceStartMessage -f $Name)

    $capability = Get-WindowsCapability -Name $Name

    $returnValue = @{
        Name        = [System.String] $Name
        LogLevel    = [system.String] $capability.LogLevel
        LimitAccess = [System.Int64] $capability.LimitAccess
        Online      = [System.Boolean] $capability.Online
        LogPath     = [System.String] $capability.LogPath
    }

    Write-Verbose -Message ($script:localizedData.GetTargetResourceEndMessage -f $Name)
    return $returnValue
}

<#
    .SYNOPSIS
        Sets if the the current state of the Windows Capability is in the desired state.

    .PARAMETER Name
        Specifies the given name of a Windows Capability.

    .PARAMETER Ensure
        Specifies whether the Windows Capability should be installed or uninstalled.

    .PARAMETER LogLevel
        Specifies the given LogLevel of a Windows Capability. The Default Level is 3.
        1 = Errors only
        2 = Errors and warnings
        3 = Errors, warnings, and information
        4 = All of the information listed previously, plus debug output.

    .PARAMETER LimitAccess
        Indicates that this cmdlet does not query Windows Update for source packages
        when servicing a live OS.
        Only applies when the -Online switch is specified.

    .PARAMETER Online
        Indicates that the cmdlet operates on a running operating system on the local host.

    .PARAMETER LogPath
        Specifies the full path and file name to log to.
        If not set, the default is %WINDIR%\Logs\Dism\dism.log
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateRange(1, 4)]
        $LogLevel,

        [Parameter()]
        [System.Boolean]
        $LimitAccess,

        [Parameter()]
        [System.Boolean]
        $Online,

        [Parameter()]
        [System.String]
        $LogPath
    )

    Write-Verbose -Message ($script:localizedData.SetTargetResourceStartMessage -f $Name)

    if ($Ensure -eq 'Present')
    {
        if ($Online -eq $true)
        {
            Add-WindowsCapability -Online -Name $Name
        }

        if ($Online -eq $false)
        {
            Add-WindowsCapability -Name $Name
        }
    }

    if ($Ensure -eq 'Absent')
    {
        if ($Online -eq $true)
        {
            Remove-WindowsCapability -Online -Name $Name
        }

        if ($Online -eq $false)
        {
            Remove-WindowsCapability -Name $Name
        }
    }

    Write-Verbose -Message ($script:localizedData.SetTargetResourceEndMessage -f $Name)
}

<#
    .SYNOPSIS
        Tests if the the current state of the Windows Capability is in the desired state.

    .PARAMETER Name
        Specifies the given name of a Windows Capability.

    .PARAMETER Ensure
        Specifies whether the Windows Capability should be installed or uninstalled.

    .PARAMETER LogLevel
        Specifies the given LogLevel of a Windows Capability. The Default Level is 3.
        1 = Errors only
        2 = Errors and warnings
        3 = Errors, warnings, and information
        4 = All of the information listed previously, plus debug output.

    .PARAMETER LimitAccess
        Indicates that this cmdlet does not query Windows Update for source packages
        when servicing a live OS.
        Only applies when the -Online switch is specified.

    .PARAMETER Online
        Indicates that the cmdlet operates on a running operating system on the local host.

    .PARAMETER LogPath
        Specifies the full path and file name to log to.
        If not set, the default is %WINDIR%\Logs\Dism\dism.log
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateRange(1, 4)]
        $LogLevel,

        [Parameter()]
        [System.Boolean]
        $LimitAccess,

        [Parameter()]
        [System.Boolean]
        $Online,

        [Parameter()]
        [System.String]
        $LogPath
    )

    Write-Verbose -Message ($script:localizedData.TestTargetResourceStartMessage -f $Name)

    $windowsCapability = Get-WindowsCapability -Name $Name

    if ($null -eq $windowsCapability)
    {
        return
    }

    $desiredState = $true

    Write-Verbose -Message ($script:localizedData.SetResourceIsInDesiredState -f $Name)

    Write-Verbose -Message ($script:localizedData.TestTargetResourceEndMessage -f $Name)
    return $desiredState
}

Export-ModuleMember -Function *-TargetResource
