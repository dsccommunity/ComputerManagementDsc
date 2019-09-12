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

    .PARAMETER Name
        Specifies the given name of a Windows Capability.
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

    $capability = Get-WindowsCapability -Name $Name -Online

    $returnValue = @{
        Name     = $Name
        LogLevel = $capability.LogLevel
        State    = $capability.State
        Ensure   = $Ensure
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
        Specifies the given LogLevel of a Windows Capability. The Default Level is 'Errors', 'Warnings', 'WarningsInfo'.
        1 = Errors only
        2 = Errors and warnings
        3 = Errors, warnings, and information
        4 = All of the information listed previously, plus debug output.

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
        [ValidateSet('Errors', 'Warnings', 'WarningsInfo')]
        [System.String]
        $LogLevel,

        [Parameter()]
        [System.String]
        $LogPath
    )

    Write-Verbose -Message ($script:localizedData.SetTargetResourceStartMessage -f $Name)

    if ($Ensure -eq 'Present')
    {
        if ($LogPath -and $LogLevel)
        {
            Add-WindowsCapability -Online -Name $Name -LogPath $LogPath -LogLevel $LogLevel
        }
        elseif ($LogPath -and !$LogLevel)
        {
            Add-WindowsCapability -Online -Name $Name -LogPath $LogPath
        }
        elseif (!$LogPath -and $LogLevel)
        {
            Add-WindowsCapability -Online -Name $Name -LogLevel $LogLevel
        }
    }

    if ($Ensure -eq 'Absent')
    {
        Remove-WindowsCapability -Online -Name $Name
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
        $Ensure = 'Present'
    )

    Write-Verbose -Message ($script:localizedData.TestTargetResourceStartMessage -f $Name)

    if ($null -eq $windowsCapability.Name)
    {
        return
    }

    if (-not (Test-Path $LogPath))
    {
        return
    }

    $desiredState = $true

    if ($windowsCapability.State -eq 'Installed')
    {
        $ensureResult = 'Present'
    }
    else
    {
        $ensureResult = 'Absent'
    }

    if ($PSBoundParameters.ContainsKey('Ensure') -and $windowsCapability.State -ne $ensureResult)
    {
        Write-Verbose -Message ($script:localizedData.SetResourceIsNotInDesiredState -f $Name)
        $desiredState = $false
    }

    Write-Verbose -Message ($script:localizedData.SetResourceIsInDesiredState -f $Name)

    return $desiredState
}

Export-ModuleMember -Function *-TargetResource
