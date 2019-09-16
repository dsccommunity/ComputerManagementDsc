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
        $Ensure = 'Absent'
    )

    Write-Verbose -Message ($script:localizedData.GetTargetResourceStartMessage -f $Name)

    $capability = Get-WindowsCapability -Name $Name -Online

    if ($capability.State -eq 'Installed')
    {
        $Ensure = 'Present'
    }

    return @{
        IsSingleInstance = 'Yes'
        Name             = $Name
        LogLevel         = $capability.LogLevel
        LogPath          = $capability.LogPath
        Ensure           = $Ensure
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
        Specifies the given LogLevel of a Windows Capability. The Default Level is 'WarningsInfo'.

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
        $Ensure = 'Absent',

        [Parameter()]
        [ValidateSet('Errors', 'Warnings', 'WarningsInfo')]
        [System.String]
        $LogLevel,

        [Parameter()]
        [System.String]
        $LogPath
    )

    Write-Verbose -Message ($script:localizedData.SetTargetResourceStartMessage -f $Name)

    $null = $PSBoundParameters.Remove('Ensure')
    $null = Add-WindowsCapability -Online @PSBoundParameters

    if ($Ensure -eq 'Absent')
    {
        $null = Remove-WindowsCapability -Online @PSBoundParameters
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
        $Ensure = 'Absent',

        [Parameter()]
        [ValidateSet('Errors', 'Warnings', 'WarningsInfo')]
        [System.String]
        $LogLevel,

        [Parameter()]
        [System.String]
        $LogPath
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
