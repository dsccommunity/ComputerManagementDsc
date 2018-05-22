$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import the ComputerManagementDsc Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.ResourceHelper' `
            -ChildPath 'ComputerManagementDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_PowershellExecutionPolicy' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

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
        [Parameter()]
        [ValidateSet("CurrentUser","LocalMachine","MachinePolicy","Process","UserPolicy")]
        [System.String]
        $ExecutionPolicyScope = 'LocalMachine',

        [Parameter(Mandatory = $true)]
        [ValidateSet("Bypass","Restricted","AllSigned","RemoteSigned","Unrestricted")]
        [System.String]
        $ExecutionPolicy
    )

    Write-Verbose -Message (Get-ExecutionPolicy -Scope $ExecutionPolicyScope)
    Write-Verbose -Message $ExecutionPolicyScope

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
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [Parameter()]
        [ValidateSet("CurrentUser","LocalMachine","MachinePolicy","Process","UserPolicy")]
        [System.String]
        $ExecutionPolicyScope = 'LocalMachine',

        [Parameter(Mandatory = $true)]
        [ValidateSet("Bypass","Restricted","AllSigned","RemoteSigned","Unrestricted")]
        [System.String]
        $ExecutionPolicy
    )

    If($PSCmdlet.ShouldProcess("$ExecutionPolicy","Set-ExecutionPolicy"))
    {
        Try
        {
            Write-Verbose "Setting the execution policy of PowerShell."
            Set-ExecutionPolicy -ExecutionPolicy $ExecutionPolicy -Force -ErrorAction Stop -Scope $ExecutionPolicyScope
        }
        Catch
        {
            if($_.toString() -like "Windows PowerShell updated your execution policy successfully*")    # trap this error, it set correctly.
            {
                Write-Verbose "$_"
            }
            else
            {
                throw
            }
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
        [Parameter()]
        [ValidateSet("CurrentUser","LocalMachine","MachinePolicy","Process","UserPolicy")]
        [System.String]
        $ExecutionPolicyScope = 'LocalMachine',

        [Parameter(Mandatory = $true)]
        [ValidateSet("Bypass","Restricted","AllSigned","RemoteSigned","Unrestricted")]
        [System.String]
        $ExecutionPolicy
    )

    Write-Verbose -Message (Get-ExecutionPolicy -Scope $ExecutionPolicyScope)
    Write-Verbose -Message $ExecutionPolicyScope

    If($(Get-ExecutionPolicy -Scope $ExecutionPolicyScope) -eq $ExecutionPolicy)
    {
        $ExecutionPolicyScope
    }
    else
    {
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource
