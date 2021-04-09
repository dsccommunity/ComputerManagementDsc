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
        Gets the current state of the Windows Capability.

    .PARAMETER Name
        Specifies the name of the Windows Capability.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Write-Verbose -Message ($script:localizedData.GetTargetResourceStartMessage -f $Name)
    $windowsCapability = Get-WindowsCapability -Online @PSBoundParameters

    if ([System.String]::IsNullOrEmpty($windowsCapability.Name))
    {
        New-InvalidArgumentException `
            -Message ($script:localizedData.CapabilityNameNotFound -f $Name) `
            -ArgumentName 'Name'
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.CapabilityNameFound -f $Name)
    }

    if ($windowsCapability.State -eq 'Installed')
    {
        $Ensure = 'Present'
    }
    else
    {
        $Ensure = 'Absent'
    }

    $returnValue = @{
        Name     = $Name
        LogLevel = $windowsCapability.LogLevel
        LogPath  = $windowsCapability.LogPath
        Ensure   = $Ensure
    }

    Write-Verbose -Message ($script:localizedData.GetTargetResourceEndMessage -f $Name)
    return $returnValue
}

<#
    .SYNOPSIS
        Sets if the the current state of the Windows Capability is in the desired state.

    .PARAMETER Name
        Specifies the name of the Windows Capability.

    .PARAMETER Ensure
        Specifies whether the Windows Capability should be installed
        or uninstalled.

    .PARAMETER LogLevel
        Specifies the given Log Level of a Windows Capability. This is a write
        only parameter that is used when updating the status of a Windows
        Capability. If not specified, the default is 'WarningsInfo'.

    .PARAMETER LogPath
        Specifies the full path and file name to log to. This is a write
        only parameter that is used when updating the status of a Windows
        Capability. If not specified, the default is '%WINDIR%\Logs\Dism\dism.log'.

    .PARAMETER Source
        Specifies the location of the files that are required to add a Windows
        capability package to an image. You can specify the Windows directory
        of a mounted image or a running Windows installation that is shared on the network.
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
        $LogPath,

        [Parameter()]
        [System.String]
        $Source
    )

    Write-Verbose -Message ($script:localizedData.SetTargetResourceStartMessage -f $Name)
    $null = $PSBoundParameters.Remove('Ensure')
    $currentState = Get-TargetResource -Name $Name

    switch ($Ensure)
    {
        'Present'
        {
            if ($Ensure -ne $currentState.Ensure)
            {
                Write-Verbose -Message ($script:localizedData.SetTargetAddMessage -f $Name)
                $null = Add-WindowsCapability -Online @PSBoundParameters
            }
        }

        'Absent'
        {
            if ($Ensure -ne $currentState.Ensure)
            {
                Write-Verbose -Message ($script:localizedData.SetTargetRemoveMessage -f $Name)

                if ($PSBoundParameters.ContainsKey('Source'))
                {
                    $PSBoundParameters.Remove('Source')
                }

                $null = Remove-WindowsCapability -Online @PSBoundParameters
            }
        }
    }
}

<#
    .SYNOPSIS
        Tests if the the current state of the Windows Capability is in the desired state.

    .PARAMETER Name
        Specifies the name of the Windows Capability.

    .PARAMETER Ensure
        Specifies whether the Windows Capability should be installed
        or uninstalled.

    .PARAMETER LogLevel
        Specifies the given Log Level of a Windows Capability. This is a write
        only parameter that is used when updating the status of a Windows
        Capability. If not specified, the default is 'WarningsInfo'.

    .PARAMETER LogPath
        Specifies the full path and file name to log to. This is a write
        only parameter that is used when updating the status of a Windows
        Capability. If not specified, the default is '%WINDIR%\Logs\Dism\dism.log'.

    .NOTES
        Get-WindowsCapability will return the LogLevel and LogPath
        properties, but these values don't reflect the values set
        when calling Add-WindowsCapability or Remove-WindowsCapability.

        Therefore, these values can not be used to determine if the
        resource is in state.
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
        [ValidateSet('Errors', 'Warnings', 'WarningsInfo')]
        [System.String]
        $LogLevel,

        [Parameter()]
        [System.String]
        $LogPath,

        [Parameter()]
        [System.String]
        $Source
    )

    $inDesiredState = $true

    Write-Verbose -Message ($script:localizedData.TestTargetResourceStartMessage -f $Name)
    $currentState = Get-TargetResource -Name $Name

    if ($Ensure -ne $currentState.Ensure)
    {
        Write-Verbose -Message ($script:localizedData.SetResourceIsNotInDesiredState -f $Name)
        $inDesiredState = $false
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.SetResourceIsInDesiredState -f $Name)
        $inDesiredState = $true
    }

    return $inDesiredState
}

Export-ModuleMember -Function *-TargetResource
