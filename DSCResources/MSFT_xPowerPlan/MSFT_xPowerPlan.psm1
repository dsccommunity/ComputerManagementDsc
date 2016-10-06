function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    try
    {
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
        IsSingleInstance = $IsSingleInstance
        Name = $activePlanName
    }
}

function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

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
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    $returnValue = $false

    $result = Get-TargetResource -IsSingleInstance $IsSingleInstance -Name $Name
    if ($result.Name -eq $Name)
    {
        $returnValue = $true
    }

    return $returnValue
}

Export-ModuleMember -Function *-TargetResource
