<#
    .SYNOPSIS
        Returns the current state of the power plan.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Name
        Specifies the name of the power plan to assign to the node.

    .EXAMPLE
        Get-TargetResource -IsSingleInstance 'Yes' -Name 'High performance'
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        # This is best practice when writing a single-instance DSC resource.
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
        $arguments = @{
            Name = 'root\cimv2\power'
            Class = 'Win32_PowerPlan'
            Filter = "ElementName = '$Name'"
        }

        $plan = Get-CimInstance @arguments
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

<#
    .SYNOPSIS
        Assign the power plan to the node.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Name
        Specifies the name of the power plan to assign to the node.

    .EXAMPLE
        Set-TargetResource -IsSingleInstance 'Yes' -Name 'High performance'
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        # This is best practice when writing a single-instance DSC resource.
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
        Write-Verbose -Message "Activating power plan $Name"

        $arguments = @{
            Name = 'root\cimv2\power'
            Class = 'Win32_PowerPlan'
            Filter = "ElementName = '$Name'"
        }

        $plan = Get-CimInstance @arguments 
        $plan | Invoke-CimMethod -MethodName Activate
    }
    catch
    {
        Throw "Unable to set the power plan $Name to the active plan. Error message: $($_.Exception.Message)" 
    }
}

<#
    .SYNOPSIS
        Tests if the power plan is assigned to the node.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Name
        Specifies the name of the power plan to assign to the node.

    .EXAMPLE
        Test-TargetResource -IsSingleInstance 'Yes' -Name 'High performance'
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        # This is best practice when writing a single-instance DSC resource.
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
