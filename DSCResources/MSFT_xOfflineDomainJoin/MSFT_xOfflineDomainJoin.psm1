$moduleRoot = Split-Path `
    -Path $MyInvocation.MyCommand.Path `
    -Parent

#region LocalizedData
$Culture = 'en-us'
if (Test-Path -Path (Join-Path -Path $moduleRoot -ChildPath $PSUICulture))
{
    $Culture = $PSUICulture
}
Import-LocalizedData `
    -BindingVariable LocalizedData `
    -Filename MSFT_xOfflineDomainJoin.psd1 `
    -BaseDirectory $moduleRoot `
    -UICulture $Culture
#endregion


function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RequestFile
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingOfflineDomainJoinMessage)
        ) -join '')

    # It is not possible to read the ODJ file that was used to join a domain
    # So it has to always be returned as blank.
    $returnValue = @{
        IsSingleInstance = 'Yes'
        RequestFile = ''
    }

    #Output the target resource
    $returnValue
} # Get-TargetResource


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RequestFile
    )

    Write-Verbose -Message ( @( "$($MyInvocation.MyCommand): "
        $($LocalizedData.ApplyingOfflineDomainJoinMessage)
        ) -join '')

    # Check the ODJ Request file exists
    if (-not (Test-Path -Path $RequestFile))
    {
        $errorId = 'RequestFileNotFoundError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
        $errorMessage = $($LocalizedData.RequestFileNotFoundError) `
            -f $RequestFile
        $exception = New-Object -TypeName System.ArgumentException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    } # if

    # Don't need to check if the domain is already joined because
    # Set-TargetResource wouldn't fire unless it wasn't.
    Join-Domain -RequestFile $RequestFile
} # Set-TargetResource


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet('Yes')]
        [System.String]
        $IsSingleInstance, 

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $RequestFile
    )

    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.CheckingOfflineDomainJoinMessage)
        ) -join '')

    # Check the ODJ Request file exists
    if (-not (Test-Path -Path $RequestFile))
    {
        $errorId = 'RequestFileNotFoundError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
        $errorMessage = $($LocalizedData.RequestFileNotFoundError) `
            -f $RequestFile
        $exception = New-Object -TypeName System.ArgumentException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    } # if

    $CurrentDomainName = Get-DomainName

    if($CurrentDomainName)
    {
        # Domain is already joined.
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.DomainAlreadyJoinedMessage) `
                -f $CurrentDomainName `
            ) -join '' )
    }
    else
    {
        # Domain is not joined, so change is required.
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.DomainNotJoinedMessage)
            ) -join '')

        $desiredConfigurationMatch = $false
    } # if
    return $desiredConfigurationMatch
} # Test-TargetResource


<#
.SYNOPSIS
Uses DJoin.exe to join a Domain using a ODJ Request File.
#>
function Join-Domain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.String]
        $RequestFile
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.AttemptingDomainJoinMessage) `
            -f $RequestFile `
        ) -join '' )

    $Result = & djoin.exe @(
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
        Write-Verbose -Message $Result

        $errorId = 'DjoinError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
        $errorMessage = $($LocalizedData.DjoinError) `
            -f $LASTEXITCODE
        $exception = New-Object -TypeName System.ArgumentException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    } # if

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.DomainJoinedMessage) `
            -f $RequestFile `
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
    $ComputerSystem = Get-CimInstance -ClassName win32_computersystem -Namespace root\cimv2
    if ($ComputerSystem.Workgroup)
    {
        return $null
    }
    else
    {
        $ComputerSystem.Domain
    }
} # function Get-DomainName


Export-ModuleMember -Function *-TargetResource
