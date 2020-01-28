$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'DSC_IEEnhancedSecurityConfiguration'

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

    $returnValue = @{
        Role            = $Role
        Enabled         = [System.Boolean] (Get-ItemProperty -Path $registryKey).$script:registryKey_Property
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
        Specifies if the needed restart is suppress. Default the node will be
        restarted if the value is changed.

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

        Set-ItemProperty -Path $registryKey -Name $script:registryKey_Property -Value $Enabled

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
        Specifies if the needed restart is suppress. Default the node will be
        restarted if the value is changed.
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

        $currentStateString = Get-StateStringValue -Enabled $getTargetResourceResult.Enabled
        $desiredStateString = Get-StateStringValue -Enabled $Enabled

        Write-Verbose -Message ($script:localizedData.NotInDesiredState -f $Role, $currentStateString, $desiredStateString)
    }
    else
    {
        $testTargetResourceReturnValue = $true

        Write-Verbose -Message ($script:localizedData.InDesiredState -f $Role)
    }

    return $testTargetResourceReturnValue
}

function Get-StateStringValue
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Boolean]
        $Enabled
    )

    $stringValue = switch ($Enabled)
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

    return $stringValue
}
