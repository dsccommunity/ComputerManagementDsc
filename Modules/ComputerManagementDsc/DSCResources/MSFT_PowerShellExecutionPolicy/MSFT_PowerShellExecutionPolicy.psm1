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
        [ValidateSet("Bypass","Restricted","AllSigned","RemoteSigned","Unrestricted")]
        [System.String]
        $ExecutionPolicy,
        [Parameter()]
        [ValidateSet("CurrentUser","LocalMachine","MachinePolicy","Process","UserPolicy")]
        [System.String]
        $ExecutionPolicyScope = 'LocalMachine'
    )

    Write-Verbose -Message (Get-ExecutionPolicy -Scope $ExecutionPolicyScope)

    #Gets the execution policies for the current session.
    $returnValue = @{
        ExecutionPolicy = $(Get-ExecutionPolicy -Scope $ExecutionPolicyScope)
        ExecutionPolicyScope = $ExecutionPolicyScope
    }

    $returnValue
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
        [Parameter(Mandatory = $true)]
        [ValidateSet("Bypass","Restricted","AllSigned","RemoteSigned","Unrestricted")]
        [System.String]
        $ExecutionPolicy,
        [Parameter()]
        [ValidateSet("CurrentUser","LocalMachine","MachinePolicy","Process","UserPolicy")]
        [System.String]
        $ExecutionPolicyScope = 'LocalMachine'
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
        [Parameter(Mandatory = $true)]
        [ValidateSet("Bypass","Restricted","AllSigned","RemoteSigned","Unrestricted")]
        [System.String]
        $ExecutionPolicy,
        [Parameter()]
        [ValidateSet("CurrentUser","LocalMachine","MachinePolicy","Process","UserPolicy")]
        [System.String]
        $ExecutionPolicyScope = 'LocalMachine'
    )

    Write-Verbose -Message (Get-ExecutionPolicy -Scope $ExecutionPolicyScope)

    If($(Get-ExecutionPolicy -Scope $ExecutionPolicyScope) -eq $ExecutionPolicy)
    {
        return $true
    }
    else
    {
        return $false
    }
}

Export-ModuleMember -Function *-TargetResource
