$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

$script:registryKey_Administrators = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}'
$script:registryKey_Users = 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}'
$script:registryKey_Property = 'IsInstalled'

<#
    .SYNOPSIS
        Gets the current state of the IE Enhanced Security Configuration.

    .PARAMETER Role
        Specifies the role for which the IE Enhanced Security Configuration
        should be changed.

    .PARAMETER Enabled
        Specifies if IE Enhanced Security Configuration should be enabled or
        disabled.

    .PARAMETER SuppressRestart
        Specifies if a restart of the node should be suppressed. By default the
        node will be restarted if the value is changed.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Administrators', 'Users')]
        [System.String]
        $Role,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart
    )

    Write-Verbose -Message ($script:localizedData.GettingStateMessage -f $Role)

    $registryKey = Get-Variable -Name ('registryKey_{0}' -f $Role) -Scope 'Script' -ValueOnly

    try
    {
        $currentlyEnabled = [System.Boolean] (Get-ItemProperty -Path $registryKey -ErrorAction 'Stop').$script:registryKey_Property
    }
    catch
    {
        $currentlyEnabled = $false

        Write-Warning -Message ($script:localizedData.UnableToDetermineState -f $registryKey)
    }

    $returnValue = @{
        Role            = $Role
        Enabled         = $currentlyEnabled
        SuppressRestart = $SuppressRestart
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the current state of the IE Enhanced Security Configuration.

    .PARAMETER Role
        Specifies the role for which the IE Enhanced Security Configuration
        should be changed.

    .PARAMETER Enabled
        Specifies if IE Enhanced Security Configuration should be enabled or
        disabled.

    .PARAMETER SuppressRestart
        Specifies if a restart of the node should be suppressed. By default the
        node will be restarted if the value is changed.

    .NOTES
        The change could come in affect if the process Explorer is stopped, which
        will make Windows automatically start a new process. But, stopping a
        process feels wrong so the resource instead restarts the node when the
        value is changed.
#>
function Set-TargetResource
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope = 'Function')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Administrators', 'Users')]
        [System.String]
        $Role,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart
    )

    $getTargetResourceResult = Get-TargetResource @PSBoundParameters

    if ($getTargetResourceResult.Enabled -ne $Enabled)
    {
        Write-Verbose -Message ($script:localizedData.SettingStateMessage -f $Role)

        $registryKey = Get-Variable -Name ('registryKey_{0}' -f $Role) -Scope 'Script' -ValueOnly

        try
        {
            $setItemPropertyParameters = @{
                Path = $registryKey
                Name = $script:registryKey_Property
                Value = $Enabled
                ErrorAction = 'Stop'
            }

            Set-ItemProperty @setItemPropertyParameters
        }
        catch
        {
            New-InvalidOperationException `
                -Message ($script:localizedData.FailedToSetDesiredState -f $Role) `
                -ErrorRecord $_
        }

        if ($SuppressRestart)
        {
            Write-Warning -Message $script:localizedData.SuppressRestart
        }
        else
        {
            $global:DSCMachineStatus = 1
        }
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.InDesiredState -f $Role)
    }
}

<#
    .SYNOPSIS
        Tests the current state of the IE Enhanced Security Configuration.

    .PARAMETER Role
        Specifies the role for which the IE Enhanced Security Configuration
        should be changed.

    .PARAMETER Enabled
        Specifies if IE Enhanced Security Configuration should be enabled or
        disabled.

    .PARAMETER SuppressRestart
        Specifies if a restart of the node should be suppressed. By default the
        node will be restarted if the value is changed.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Administrators', 'Users')]
        [System.String]
        $Role,

        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Enabled,

        [Parameter()]
        [System.Boolean]
        $SuppressRestart
    )

    Write-Verbose -Message ($script:localizedData.TestingStateMessage -f $Role)

    $getTargetResourceResult = Get-TargetResource @PSBoundParameters

    if ($getTargetResourceResult.Enabled -ne $Enabled)
    {
        $testTargetResourceReturnValue = $false

        $currentStateString = Get-BooleanStringValue -Enabled $getTargetResourceResult.Enabled
        $desiredStateString = Get-BooleanStringValue -Enabled $Enabled

        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $Role, $currentStateString, $desiredStateString)
    }
    else
    {
        $testTargetResourceReturnValue = $true

        Write-Verbose -Message ($script:localizedData.InDesiredState -f $Role)
    }

    return $testTargetResourceReturnValue
}

<#
    .SYNOPSIS
        Returns the string representation of a boolean value.

    .PARAMETER Enabled
        Specifies the boolean value to return the string representation for.
#>
function Get-BooleanStringValue
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Enabled
    )

    $booleanStringValue = switch ($Enabled)
    {
        $false
        {
            'disabled'
        }

        $true
        {
            'enabled'
        }
    }

    return $booleanStringValue
}
