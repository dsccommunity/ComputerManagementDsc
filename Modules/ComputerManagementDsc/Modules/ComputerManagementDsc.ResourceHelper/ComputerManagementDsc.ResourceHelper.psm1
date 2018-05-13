<#
    .SYNOPSIS
    Tests if the specified command can be found.

    .PARAMETER name
    The name of the command to test.
#>
function Test-Command
{
    param
    (
        [String] $Name
    )

    return ($null -ne (Get-Command -Name $Name -ErrorAction Continue 2> $null))
}

<#
    .SYNOPSIS
    Tests if the current machine is a Nano server.
#>
function Test-IsNanoServer
{
    if(Test-Command -Name Get-ComputerInfo)
    {
        $computerInfo = Get-ComputerInfo

        if("Server" -eq $computerInfo.OsProductType `
            -and "NanoServer" -eq $computerInfo.OsServerLevel)
        {
            return $true
        }
    }

    return $false
}

<#
    .SYNOPSIS
        Creates and throws an invalid argument exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown
#>
function New-InvalidArgumentException
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
    $errorRecord = New-Object @newObjectParams

    throw $errorRecord
}

<#
    .SYNOPSIS
        Creates and throws an invalid operation exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error
#>
function New-InvalidOperationException
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
    $errorRecordToThrow = New-Object @newObjectParams
    throw $errorRecordToThrow
}

<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture.
        Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
        The name of the resource as it appears before '.strings.psd1' of the localized string file.

        For example:
            For WindowsOptionalFeature: MSFT_xWindowsOptionalFeature
            For Service: MSFT_xServiceResource
            For Registry: MSFT_xRegistryResource
#>
function Get-LocalizedData
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ResourceName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ResourcePath
    )

    $localizedStringFileLocation = Join-Path -Path $ResourcePath -ChildPath $PSUICulture

    if (-not (Test-Path -Path $localizedStringFileLocation))
    {
        # Fallback to en-US
        $localizedStringFileLocation = Join-Path -Path $ResourcePath -ChildPath 'en-US'
    }

    Import-LocalizedData `
        -BindingVariable 'localizedData' `
        -FileName "$ResourceName.strings.psd1" `
        -BaseDirectory $localizedStringFileLocation

    return $localizedData
}

Export-ModuleMember -Function `
    Test-IsNanoServer, `
    New-InvalidArgumentException, `
    New-InvalidOperationException, `
    Get-LocalizedData
