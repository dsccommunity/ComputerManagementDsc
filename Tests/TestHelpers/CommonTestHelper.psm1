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
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

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
        Returns the current Time Zone. This method is used because the
        Get-Timezone cmdlet is not available on OS versions prior to
        Windows 10/Windows Server 2016.
#>
function Get-TimeZoneId
{
    [CmdletBinding()]
    param()

    $TimeZone = (Get-CimInstance `
        -ClassName WIN32_Timezone `
        -Namespace root\cimv2).StandardName

    $timeZoneInfo = [System.TimeZoneInfo]::GetSystemTimeZones() |
        Where-Object StandardName -eq $TimeZone

    return $timeZoneInfo.Id
} # function Get-TimeZoneId

<#
    .SYNOPSIS
        Set the current Time Zone. This method is used because the
        Set-Timezone cmdlet is not available on OS versions prior to
        Windows 10/Windows Server 2016.

    .PARAMETER Id
        The Id of the Timezone to set the system to.
#>
function Set-TimeZoneId
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $Id
    )

    try
    {
        & tzutil.exe @('/s',$Id)
    }
    catch
    {
        $ErrorMsg = $_.Exception.Message
        Write-Verbose -Message $ErrorMsg
    } # try
} # function Set-TimeZoneId

Export-ModuleMember -Function `
    Get-TimeZoneId, `
    Set-TimeZoneId, `
    Get-InvalidArgumentRecord, `
    Get-InvalidOperationRecord
