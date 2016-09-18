function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $Name = 'High performance'
    )

    try
    {
        if ($Ensure -eq 'Absent' )
        {
            # Hard-coded to plan name 'Balanced' because that is the default plan after OS installation
            $Name = 'Balanced' 
        }
        
        $plan = Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan -Filter "ElementName = '$Name'"
        if ($plan)
        {
            if( $plan.IsActive )
            {
                Write-Verbose "$Name is the active plan"
                $activePlanName = $Name
            }
            else
            {
                Write-Verbose "$Name is the not active plan"
            }
        }
        else
        {
            throw "Unable to find the power plan $Name." 
        }
    }
    catch
    {
        throw $_
    }

    $returnValue = @{
        Ensure = $Ensure
        Name = $activePlanName
    }
    
    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $Name = 'High performance'
    )

    try
    {

        if ($Ensure -eq 'Absent' )
        {
            # Hard-coded to plan name 'Balanced' because that is the default plan after OS installation
            $Name = 'Balanced' 
        }

        if ($PSCmdlet.ShouldProcess($Name, 'Activating power plan'))
        {
            $plan = Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan -Filter "ElementName = '$Name'" 
            Invoke-CimMethod -InputObject $plan -MethodName Activate
        }
    }
    catch
    {
        throw $_
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $Name = 'High performance'
    )

    $returnValue = $false

    $result = Get-TargetResource -Ensure $Ensure -Name $Name
    if ($result.Ensure -eq 'Present' -and $result.Name -eq $Name )
    {
        $returnValue = $true
    }
    elseif ($result.Ensure -eq 'Absent' -and $result.Name -eq 'Balanced' )
    {
        $returnValue = $true
    }

    return $returnValue
}

Export-ModuleMember -Function *-TargetResource
