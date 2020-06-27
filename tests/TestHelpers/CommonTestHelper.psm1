<#
    .SYNOPSIS
        Returns an invalid argument exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown
#>
function Get-InvalidArgumentRecord
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ArgumentName
    )

    $argumentException = New-Object -TypeName 'ArgumentException' -ArgumentList @( $Message,
        $ArgumentName )
    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $argumentException, $ArgumentName, 'InvalidArgument', $null )
    }
    return New-Object @newObjectParams
}

<#
    .SYNOPSIS
        Returns an invalid operation exception object

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error
#>
function Get-InvalidOperationRecord
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $Message)
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException'
    }
    elseif ($null -eq $ErrorRecord)
    {
        $invalidOperationException =
        New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message )
    }
    else
    {
        $invalidOperationException =
        New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message,
            $ErrorRecord.Exception )
    }

    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $invalidOperationException.ToString(), 'MachineStateIncorrect',
            'InvalidOperation', $null )
    }
    return New-Object @newObjectParams
}

<#
    .SYNOPSIS
        Test if the source files are available for Windows Capability.
        If the source files are not available Get-WindowsCapability
        will throw an exception.
#>
function Test-WindowsCapabilitySourceAvailable
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param ()

    $sourceAvailable = $true

    try
    {
        Get-WindowsCapability -Online -ErrorAction Stop
    }
    catch
    {
        $sourceAvailable = $false
    }

    return $sourceAvailable
}

<#
    .SYNOPSIS
        Resets the DSC LCM by performing the following functions:
        1. Cancel any currently executing DSC LCM operations
        2. Remove any DSC configurations that:
            - are currently applied
            - are pending application
            - have been previously applied
        The purpose of this function is to ensure the DSC LCM is in a known
        and idle state before an integration test is performed that will
        apply a configuration.
        This is to prevent an integration test from being performed but failing
        because the DSC LCM is applying a previous configuration.
        This function should be called after each Describe block in an integration
        test to ensure the DSC LCM is reset before another test DSC configuration
        is applied.
    .EXAMPLE
        PS C:\> Reset-DscLcm
        This command will reset the DSC LCM and clear out any DSC configurations.
#>
function Reset-DscLcm
{
    [CmdletBinding()]
    param ()

    Write-Verbose -Message 'Resetting DSC LCM.'

    Stop-DscConfiguration -Force -ErrorAction SilentlyContinue
    Remove-DscConfigurationDocument -Stage Current -Force
    Remove-DscConfigurationDocument -Stage Pending -Force
    Remove-DscConfigurationDocument -Stage Previous -Force
}

Export-ModuleMember -Function `
    Get-InvalidArgumentRecord, `
    Get-InvalidOperationRecord, `
    Test-WindowsCapabilitySourceAvailable, `
    Reset-DscLcm
