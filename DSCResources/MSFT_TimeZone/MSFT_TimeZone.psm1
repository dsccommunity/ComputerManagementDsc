$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import the ComputerManagementDsc Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.ResourceHelper' `
            -ChildPath 'ComputerManagementDsc.ResourceHelper.psm1'))

# Import Localization Strings.
$LocalizedData = Get-LocalizedData `
    -ResourceName 'MSFT_TimeZone' `
    -ResourcePath (Split-Path -Parent $script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        Returns the current time zone of the node.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER TimeZone
        Specifies the time zone.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TimeZone
    )

    Write-Verbose -Message ($LocalizedData.GettingTimeZoneMessage)

    # Get the current time zone Id.
    $currentTimeZone = Get-TimeZoneId

    $returnValue = @{
        IsSingleInstance = 'Yes'
        TimeZone         = $currentTimeZone
    }

    # Output the target resource.
    return $returnValue
}

<#
    .SYNOPSIS
        Sets the current time zone of the node.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER TimeZone
        Specifies the time zone.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TimeZone
    )

    $currentTimeZone = Get-TimeZoneId

    if ($currentTimeZone -ne $TimeZone)
    {
        Write-Verbose -Message ($LocalizedData.SettingTimeZoneMessage)
        Set-TimeZoneId -TimeZone $TimeZone
    }
    else
    {
        Write-Verbose -Message ($LocalizedData.TimeZoneAlreadySetMessage -f $TimeZone)
    }
}

<#
    .SYNOPSIS
        Tests the current time zone of the node.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER TimeZone
        Specifies the time zone.
#>
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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $TimeZone
    )

    Write-Verbose -Message ($LocalizedData.TestingTimeZoneMessage)

    return Test-TimeZoneId -TimeZoneId $TimeZone
}

Export-ModuleMember -Function *-TargetResource
