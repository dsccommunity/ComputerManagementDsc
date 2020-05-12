$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

Import-Module -Name (Join-Path -Path $modulePath -ChildPath 'DscResource.Common')

# Import Localization Strings
$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

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

    $desiredPowerPlan = Get-PowerPlan -PowerPlan $Name

    if ($desiredPowerPlan)
    {
        $activePowerPlan = Get-ActivePowerPlan

        if ($activePowerPlan -eq $desiredPowerPlan.Guid)
        {
            Write-Verbose -Message ($script:localizedData.PowerPlanIsActive -f $desiredPowerPlan.FriendlyName)
            $isActive = $true
        }
        else
        {
            Write-Verbose -Message ($script:localizedData.PowerPlanIsNotActive -f $desiredPowerPlan.FriendlyName)
            $isActive = $false
        }

        return @{
            IsSingleInstance = $IsSingleInstance
            Name             = $Name
            IsActive         = $isActive
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

    $desiredPowerPlan = Get-PowerPlan -PowerPlan $Name

    if ($desiredPowerPlan)
    {
        Set-ActivePowerPlan -PowerPlanGuid $desiredPowerPlan.Guid
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
