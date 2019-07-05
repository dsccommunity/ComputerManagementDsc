$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'MSFT_RemoteDesktopAdmin'

$script:tSRegistryKey = 'HKLM:\System\CurrentControlSet\Control\Terminal Server'
$script:winStationsRegistryKey = 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'

<#
    .SYNOPSIS
    Returns the current Remote Desktop Admin Settings.

    .PARAMETER IsSingleInstance
    Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Ensure
    Specifies whether Remote Desktop connections should be allowed (Present) or denied (Absent).
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

    $targetResource = @{
        IsSingleInstance   = $IsSingleInstance
        Ensure             = switch ($fDenyTSConnectionsRegistry)
        {
            0
            {
                "Present"
            }
            1
            {
                "Absent"
            }
        }
        UserAuthentication = switch ($UserAuthenticationRegistry)
        {
            0
            {
                "NonSecure"
            }
            1
            {
                "Secure"
            }
        }
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet("NonSecure", "Secure")]
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
        [ValidateSet("Present", "Absent")]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [ValidateSet("NonSecure", "Secure")]
        [System.String]
        $UserAuthentication
    )

    switch ($Ensure)
    {
        "Present"
        {
            $fDenyTSConnectionsRegistry = 0
            break
        }
        "Absent"
        {
            $fDenyTSConnectionsRegistry = 1
            break
        }
    }

    switch ($UserAuthentication)
    {
        "NonSecure"
        {
            $UserAuthenticationRegistry = 0
            break
        }
        "Secure"
        {
            $UserAuthenticationRegistry = 1
            break
        }
    }

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
