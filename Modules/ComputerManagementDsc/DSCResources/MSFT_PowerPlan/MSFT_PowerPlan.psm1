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
    -ResourceName 'MSFT_PowerPlan' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        Returns the current state of the power plan.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Name
        Specifies the name or GUID of the power plan to assign to the node.

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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    $plan = Get-PowerPlans | Where-Object{($_.Name -eq $Name) -or ($_.Guid -eq $Name)}

    if ($plan)
    {
        if ($plan.IsActive)
        {
            Write-Verbose -Message ($script:localizedData.PowerPlanIsActive -f $Name)
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.PowerPlanIsNotActive -f $Name)
        }
    }
    else
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.PowerPlanNotFound -f $Name)
    }

    return @{
        IsSingleInstance = $IsSingleInstance
        Name             = $Name
        IsActive         = $plan.IsActive
    }
}

<#
    .SYNOPSIS
        Assign the power plan to the node.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Name
        Specifies the name or GUID of the power plan to assign to the node.

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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    Write-Verbose -Message ($script:localizedData.PowerPlanIsBeingActivated -f $Name)

    $plan = Get-PowerPlans | Where-Object{($_.Name -eq $Name) -or ($_.Guid -eq $Name)}

    if($plan)
    {
        try
        {
            powercfg.exe /S $plan.Guid
            if (-not $?)
            {
                Throw $error[0]
            }
        }
        catch
        {
            New-InvalidOperationException `
                -Message ($script:localizedData.PowerPlanWasUnableToBeSet -f $Name, $_.Exception.Message)
        }
    }
    else
    {
        New-InvalidOperationException `
        -Message ($script:localizedData.PowerPlanNotFound -f $Name)
    }
}

<#
    .SYNOPSIS
        Tests if the power plan is assigned to the node.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER Name
        Specifies the name or GUID of the power plan to assign to the node.

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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    Write-Verbose -Message ($script:localizedData.PowerPlanIsBeingValidated -f $Name)

    $getTargetResourceResult = Get-TargetResource -IsSingleInstance $IsSingleInstance -Name $Name

    return $getTargetResourceResult.IsActive
}

Export-ModuleMember -Function *-TargetResource
