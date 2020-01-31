$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import Localization Strings.
$script:localizedData = Get-LocalizedData -ResourceName 'DSC_TimeZone'

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

    Write-Verbose -Message ($script:localizedData.GettingTimeZoneMessage)

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
        Write-Verbose -Message ($script:localizedData.SettingTimeZoneMessage)
        Set-TimeZoneId -TimeZone $TimeZone
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.TimeZoneAlreadySetMessage -f $TimeZone)
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

    Write-Verbose -Message ($script:localizedData.TestingTimeZoneMessage)

    return Test-TimeZoneId -TimeZoneId $TimeZone
}

Export-ModuleMember -Function *-TargetResource
