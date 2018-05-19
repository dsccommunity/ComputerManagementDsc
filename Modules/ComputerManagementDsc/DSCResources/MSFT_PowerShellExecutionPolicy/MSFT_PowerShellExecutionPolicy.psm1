#---------------------------------------------------------------------------------
#The sample scripts are not supported under any Microsoft standard support
#program or service. The sample scripts are provided AS IS without warranty
#of any kind. Microsoft further disclaims all implied warranties including,
#without limitation, any implied warranties of merchantability or of fitness for
#a particular purpose. The entire risk arising out of the use or performance of
#the sample scripts and documentation remains with you. In no event shall
#Microsoft, its authors, or anyone else involved in the creation, production, or
#delivery of the scripts be liable for any damages whatsoever (including,
#without limitation, damages for loss of business profits, business interruption,
#loss of business information, or other pecuniary loss) arising out of the use
#of or inability to use the sample scripts or documentation, even if Microsoft
#has been advised of the possibility of such damages
#---------------------------------------------------------------------------------

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

    #Gets the execution policies for the current session.
    $returnValue = @{
        ExecutionPolicy = $(Get-ExecutionPolicy -Scope $ExecutionPolicyScope)
        ExecutionPolicyScope = $ExecutionPolicyScope
    }

    $returnValue
}


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
            if($_.toString() -like "Windows PowerShell updated your execution policy successfully*")    # trap this error, it set correctlly.
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
