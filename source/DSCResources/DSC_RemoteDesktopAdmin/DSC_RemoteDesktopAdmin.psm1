$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

$script:tSRegistryKey = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
$script:winStationsRegistryKey = 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'

<#
    .SYNOPSIS
    Returns the current Remote Desktop Admin Settings.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance
    )

    Write-Verbose -Message $script:localizedData.GettingRemoteDesktopAdminSettingsMessage
    $fDenyTSConnectionsRegistry = (Get-ItemProperty -Path $script:tSRegistryKey -Name 'fDenyTSConnections').fDenyTSConnections
    $UserAuthenticationRegistry = (Get-ItemProperty -Path $script:winStationsRegistryKey -Name 'UserAuthentication').UserAuthentication

    if ($fDenyTSConnectionsRegistry -eq 0)
    {
        $ensure = 'Present'
    }
    else
    {
        $ensure = 'Absent'
    }

    if ($UserAuthenticationRegistry -eq 1)
    {
        $userAuthentication = 'Secure'
    }
    else
    {
        $userAuthentication = 'NonSecure'
    }

    $targetResource = @{
        IsSingleInstance   = $IsSingleInstance
        Ensure             = $ensure
        UserAuthentication = $userAuthentication
    }

    return $targetResource
}

<#
    .SYNOPSIS
    Tests the state of the Remote Desktop Admin Settings.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Ensure
    Specifies whether Remote Desktop connections should be allowed (Present) or denied (Absent).

    .PARAMETER UserAuthentication
    Specifies whether Remote Desktop connnections will require Network Level Authentication (Secure)
    or not (NonSecure).
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('NonSecure', 'Secure')]
        [System.String]
        $UserAuthentication
    )

    $targetResource = Get-TargetResource -IsSingleInstance 'Yes'
    $inDesiredState = $true

    if ($targetResource.Ensure -ne $Ensure)
    {
        Write-Verbose -Message ($script:localizedData.NotInDesiredStateMessage `
                -f $Ensure, $targetResource.Ensure)

        $inDesiredState = $false
    }

    if ($PSBoundParameters.ContainsKey('UserAuthentication') -and $targetResource.UserAuthentication -ne $UserAuthentication)
    {
        Write-Verbose -Message ($script:localizedData.ParameterNeedsUpdateMessage `
                -f 'UserAuthentication', $UserAuthentication, $targetResource.UserAuthentication)

        $inDesiredState = $false
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
    Sets the Remote Desktop Admin Settings.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Ensure
    Specifies whether Remote Desktop connections should be allowed (Present) or denied (Absent).

    .PARAMETER UserAuthentication
    Specifies whether Remote Desktop connnections will require Network Level Authentication (Secure)
    or not (NonSecure).
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [String]
        $IsSingleInstance,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet('NonSecure', 'Secure')]
        [System.String]
        $UserAuthentication
    )

    $fDenyTSConnectionsRegistry = @{
        Present = 0
        Absent  = 1
    }[$Ensure]

    $UserAuthenticationRegistry = @{
        NonSecure = 0
        Secure    = 1
    }[$UserAuthentication]

    $targetResource = Get-TargetResource -IsSingleInstance 'Yes'

    if ($Ensure -ne $targetResource.Ensure)
    {
        Write-Verbose -Message ($script:localizedData.SettingRemoteDesktopAdminMessage -f $Ensure)
        Set-ItemProperty -Path $script:tSRegistryKey -Name "fDenyTSConnections" -Value $fDenyTSConnectionsRegistry
    }

    if ($UserAuthentication -ne $targetResource.UserAuthentication)
    {
        Write-Verbose -Message ($script:localizedData.SettingUserAuthenticationMessage -f $UserAuthentication)
        Set-ItemProperty -Path $script:winStationsRegistryKey -Name "UserAuthentication" -Value $UserAuthenticationRegistry
    }
}

Export-ModuleMember -Function *-TargetResource
