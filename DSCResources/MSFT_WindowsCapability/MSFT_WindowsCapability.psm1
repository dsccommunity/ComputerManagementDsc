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

    $windowsCapability = Get-WindowsCapability -Online @PSBoundParameters

    if ($windowsCapability.State -eq 'Installed')
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }

    $returnValue = @{
        Name             = $Name
        LogLevel         = $windowsCapability.LogLevel
        State            = $windowsCapability.State
        Ensure           = $Ensure
        IsSingleInstance = 'Yes'
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
        Specifies the given LogLevel of a Windows Capability.
        Default LogLevel is: 'WarningsInfo'

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
    $null = $PSBoundParameters.Remove('Ensure')
    $windowsCapability = Get-WindowsCapability -Online @PSBoundParameters

    if ($windowsCapability.State -eq 'Installed')
    {
        $ensureResult = 'Present'
    }
    else
    {
        $ensureResult = 'Absent'
    }

    switch ($Ensure)
    {
        'Present'
        {
            if ($Ensure -ne $ensureResult)
            {
                Write-Verbose -Message ($script:localizedData.SetTargetAddMessage -f $Name)
                $null = Add-WindowsCapability -Online @PSBoundParameters
            }
        }

        'Absent'
        {
            if ($Ensure -ne $ensureResult)
            {
                Write-Verbose -Message ($script:localizedData.SetTargetRemoveMessage -f $Name)
                $null = Remove-WindowsCapability -Online @PSBoundParameters
            }
        }
    }
}

<#
    .SYNOPSIS
        Tests if the the current state of the Windows Capability is in the desired state.

    .PARAMETER Name
        Specifies the given name of a Windows Capability.

    .PARAMETER Ensure
        Specifies whether the Windows Capability should be installed or uninstalled.

    .PARAMETER LogLevel
        Specifies the given LogLevel of a Windows Capability.
        Default LogLevel is: 'WarningsInfo'

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
        $Ensure,

        [Parameter()]
        [ValidateSet('Errors', 'Warnings', 'WarningsInfo')]
        [System.String]
        $LogLevel,

        [Parameter()]
        [System.String]
        $LogPath
    )

    Write-Verbose -Message ($script:localizedData.TestTargetResourceStartMessage -f $Name)

    $desiredState = $true

    $windowsCapability = Get-WindowsCapability -Online @PSBoundParameters

    if ($null -eq $windowsCapability.Name)
    {
        New-InvalidArgumentException -Message ($script:localizedData.CapabilityNameNotFound -f $Name)
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.CapabilityNameFound -f $Name)
    }

    if ($LogPath)
    {
        if (-not (Test-Path $LogPath))
        {
            New-InvalidArgumentException -Message ($script:localizedData.LogPathFailedMessage -f $LogPath)
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.LogPathFoundMessage -f $LogPath)
        }
    }

    if ($windowsCapability.State -eq 'Installed')
    {
        $ensureResult = 'Present'
    }
    else
    {
        $ensureResult = 'Absent'
    }

    if ($PSBoundParameters.ContainsKey('Ensure') -and $Ensure -ne $ensureResult)
    {
        Write-Verbose -Message ($script:localizedData.SetResourceIsNotInDesiredState -f $Name)
        $desiredState = $false
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.SetResourceIsInDesiredState -f $Name)
        $desiredState = $true
    }
    return $desiredState
}

Export-ModuleMember -Function *-TargetResource
