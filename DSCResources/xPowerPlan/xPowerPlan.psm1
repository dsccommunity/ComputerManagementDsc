$script:presentStateDefaultPlanName = 'High performance'
# Absent state is hard-coded to plan name 'Balanced' because that is the default plan after OS installation
$script:absentStateDefaultPlanName = 'Balanced'

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
        $Name = $script:presentStateDefaultPlanName
    )

    try
    {
        if ($Ensure -eq 'Absent' )
        {
            $Name = $script:absentStateDefaultPlanName 
        }
        
        $plan = Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan -Filter "ElementName = '$Name'"
        if ($plan)
        {
            if( $plan.IsActive )
            {
                Write-Verbose "The power plan '$Name' is the active plan"
                $activePlanName = $Name
            }
            else
            {
                Write-Verbose "The power plan '$Name' is not the active plan"
                $activePlanName = $null
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

    return @{
        Ensure = $Ensure
        Name = $activePlanName
    }
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
        $Name = $script:presentStateDefaultPlanName
    )

    if ($Ensure -eq 'Absent' )
    {
        $Name = $script:absentStateDefaultPlanName
    }

    if ($PSCmdlet.ShouldProcess($Name, 'Activating power plan'))
    {
        try
        {
            $plan = Get-CimInstance -Name root\cimv2\power -Class Win32_PowerPlan -Filter "ElementName = '$Name'" 
            Invoke-CimMethod -InputObject $plan -MethodName Activate
        }
        catch
        {
            Throw "Unable to set the power plan $Name to the active plan. Error message: $($_.Exception.Message)" 
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
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $Name = $script:presentStateDefaultPlanName
    )

    $returnValue = $false

    $result = Get-TargetResource -Ensure $Ensure -Name $Name
    if ($result.Ensure -eq 'Present' -and $result.Name -eq $Name )
    {
        $returnValue = $true
    }
    elseif ($result.Ensure -eq 'Absent' -and $result.Name -eq $script:absentStateDefaultPlanName )
    {
        $returnValue = $true
    }

    return $returnValue
}

Export-ModuleMember -Function *-TargetResource
