$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'DSC_PowershellExecutionPolicy'

<#
    .SYNOPSIS
        Gets the current resource state.

    .PARAMETER ExecutionPolicy
        Specifies the given Powershell Execution Policy

    .PARAMETER ExecutionPolicyScope
        Specifies the given Powershell Execution Policy Scope
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('CurrentUser','LocalMachine','MachinePolicy','Process','UserPolicy')]
        [System.String]
        $ExecutionPolicyScope,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Bypass','Restricted','AllSigned','RemoteSigned','Unrestricted')]
        [System.String]
        $ExecutionPolicy
    )

    Write-Verbose -Message ($script:localizedData.GettingPowerShellExecutionPolicy -f $ExecutionPolicyScope, $ExecutionPolicy)

    # Gets the execution policies for the current session.
    $returnValue = @{
        ExecutionPolicyScope = $ExecutionPolicyScope
        ExecutionPolicy = $(Get-ExecutionPolicy -Scope $ExecutionPolicyScope)
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the desired resource state.

    .PARAMETER ExecutionPolicy
        Specifies the given Powershell Execution Policy

    .PARAMETER ExecutionPolicyScope
        Specifies the given Powershell Execution Policy Scope
#>

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('CurrentUser','LocalMachine','MachinePolicy','Process','UserPolicy')]
        [System.String]
        $ExecutionPolicyScope,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Bypass','Restricted','AllSigned','RemoteSigned','Unrestricted')]
        [System.String]
        $ExecutionPolicy
    )

    Write-Verbose -Message ($script:localizedData.SettingPowerShellExecutionPolicy -f $ExecutionPolicyScope, $ExecutionPolicy)

    try
    {
        Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Scope $ExecutionPolicyScope -Force -ErrorAction Stop
        Write-Verbose -Message ($script:localizedData.UpdatePowershellExecutionPolicySuccess -f $ExecutionPolicyScope, $ExecutionPolicy)
    }
    catch
    {
        if ($_.FullyQualifiedErrorId -eq 'ExecutionPolicyOverride,Microsoft.PowerShell.Commands.SetExecutionPolicyCommand')
        {
            Write-Verbose -Message ($script:localizedData.UpdatePowershellExecutionPolicyFailed -f $ExecutionPolicyScope, $ExecutionPolicy)
        }
        else
        {
            throw
        }
    }
}

<#
    .SYNOPSIS
        Tests if the current resource state matches the desired resource state.

    .PARAMETER ExecutionPolicy
        Specifies the given Powershell Execution Policy

    .PARAMETER ExecutionPolicyScope
        Specifies the given Powershell Execution Policy Scope
#>

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('CurrentUser','LocalMachine','MachinePolicy','Process','UserPolicy')]
        [System.String]
        $ExecutionPolicyScope,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Bypass','Restricted','AllSigned','RemoteSigned','Unrestricted')]
        [System.String]
        $ExecutionPolicy
    )

    Write-Verbose -Message ($script:localizedData.TestingPowerShellExecutionPolicy -f $ExecutionPolicyScope, $ExecutionPolicy)

    if ((Get-ExecutionPolicy -Scope $ExecutionPolicyScope) -eq $ExecutionPolicy)
    {
        return $true
    }
    else
    {
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource
