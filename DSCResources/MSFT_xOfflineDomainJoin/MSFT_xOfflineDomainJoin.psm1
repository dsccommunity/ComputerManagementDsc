[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "", Scope = "Function")]
param
(
)

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
    -ResourceName 'MSFT_xOfflineDomainJoin' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

<#
    .SYNOPSIS
        Joins the computer to a domain with a domain join file.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.
        This value is Not used in Get-TargetResource.

    .PARAMETER RequestFile
        The full path to the Offline Domain Join Request file to use.
        This value is not used in Get-TargetResource.
#>
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

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RequestFile
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($script:localizedData.GettingOfflineDomainJoinMessage)
        ) -join '')

    <#
        It is not possible to read the ODJ file that was used to join a domain
        So it has to always be returned as blank.
    #>
    $returnValue = @{
        IsSingleInstance = 'Yes'
        RequestFile      = ''
    }

    return $returnValue
} # Get-TargetResource

<#
    .SYNOPSIS
        Sets the current state of the offline domain join.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER RequestFile
        The full path to the Offline Domain Join Request file to use.
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
        $RequestFile
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
            $($script:localizedData.ApplyingOfflineDomainJoinMessage)
        ) -join '')

    # Check the ODJ Request file exists
    if (-not (Test-Path -Path $RequestFile))
    {
        New-InvalidArgumentException `
            -Message ($script:localizedData.RequestFileNotFoundError -f $RequestFile) `
            -ArgumentName 'RequestFile'
    } # if

    <#
        Don't need to check if the domain is already joined because
        Set-TargetResource wouldn't fire unless it wasn't.
    #>
    Join-Domain -RequestFile $RequestFile
} # Set-TargetResource

<#
    .SYNOPSIS
        Tests the current state of the machine joining a domain using
        an offline domain join file.

    .PARAMETER IsSingleInstance
        Specifies the resource is a single instance, the value must be 'Yes'.

    .PARAMETER RequestFile
        The full path to the Offline Domain Join Request file to use.
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
        $RequestFile
    )

    # Flag to signal whether settings are correct
    [System.Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($script:localizedData.CheckingOfflineDomainJoinMessage)
        ) -join '')

    # Check the ODJ Request file exists
    if (-not (Test-Path -Path $RequestFile))
    {
        New-InvalidArgumentException `
            -Message ($script:localizedData.RequestFileNotFoundError -f $RequestFile) `
            -ArgumentName 'RequestFile'
    } # if

    $currentDomainName = Get-DomainName

    if ($currentDomainName)
    {
        # Domain is already joined.
        Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($script:localizedData.DomainAlreadyJoinedMessage -f $CurrentDomainName) `
            ) -join '' )
    }
    else
    {
        # Domain is not joined, so change is required.
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
                $($script:localizedData.DomainNotJoinedMessage)
            ) -join '')

        $desiredConfigurationMatch = $false
    } # if

    return $desiredConfigurationMatch
} # Test-TargetResource

<#
    .SYNOPSIS
        Uses DJoin.exe to join a Domain using a ODJ Request File.
#>
function Join-Domain
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $RequestFile
    )

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.AttemptingDomainJoinMessage -f $RequestFile) `
        ) -join '' )

    $djoinResult = & djoin.exe @(
        '/REQUESTODJ'
        '/LOADFILE'
        $RequestFile
        '/WINDOWSPATH'
        $ENV:SystemRoot
        '/LOCALOS')

    if ($LASTEXITCODE -eq 0)
    {
        # Notify DSC that a reboot is required.
        $global:DSCMachineStatus = 1
    }
    else
    {
        Write-Verbose -Message $djoinResult

        New-InvalidOperationException `
            -Message ($script:localizedData.DjoinError -f $LASTEXITCODE)
    } # if

    Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($script:localizedData.DomainJoinedMessage -f $RequestFile) `
        ) -join '' )
} # function Join-Domain

<#
    .SYNOPSIS
        Returns the name of the Domain the computer is joined to or
        $null if not domain joined.
#>
function Get-DomainName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param()

    # Use CIM to detect the domain name so that this will work on Nano Server.
    $computerSystem = Get-CimInstance -ClassName 'Win32_ComputerSystem' -Namespace root\cimv2

    if ($computerSystem.Workgroup)
    {
        return $null
    }
    else
    {
        $computerSystem.Domain
    }
} # function Get-DomainName

Export-ModuleMember -Function *-TargetResource
