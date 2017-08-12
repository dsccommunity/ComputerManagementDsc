<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture.
        Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
        The name of the resource as it appears before '.strings.psd1' of the localized string file.
        For example:
            xSQLServerEndpoint: MSFT_xSQLServerEndpoint
            xSQLServerConfiguration: MSFT_xSQLServerConfiguration
            xSQLServerRole: MSFT_xSQLServerRole
#>
function Get-LocalizedData
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ResourceName
    )

    $resourceDirectory = Join-Path -Path $PSScriptRoot -ChildPath $ResourceName
    $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath $PSUICulture

    if (-not (Test-Path -Path $localizedStringFileLocation))
    {
        # Fallback to en-US
        $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath 'en-US'
    }

    Import-LocalizedData `
        -BindingVariable 'localizedData' `
        -FileName "$ResourceName.strings.psd1" `
        -BaseDirectory $localizedStringFileLocation

    return $localizedData
}

<#
.SYNOPSIS
    Removes common parameters from a hashtable
.DESCRIPTION
    This function serves the purpose of removing common parameters and option common parameters from a parameter hashtable
.PARAMETER Hashtable
    The parameter hashtable that should be pruned
#>
function Remove-CommonParameter
{
    [OutputType([System.Collections.Hashtable])]
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Hashtable
    )

    $inputClone = $Hashtable.Clone()
    $commonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters
    $commonParameters += [System.Management.Automation.PSCmdlet]::OptionalCommonParameters

    $Hashtable.Keys | Where-Object { $_ -in $commonParameters } | ForEach-Object {
        $inputClone.Remove($_)
    }

    return $inputClone
}

<#
.SYNOPSIS
    Tests the status of DSC resource parameters
.DESCRIPTION
    This function tests the parameter status of DSC resource parameters against the current values present on the system
.PARAMETER CurrentValues
    A hashtable with the current values on the system, obtained by e.g. Get-TargetResource
.PARAMETER DesiredValues
    The hashtable of desired values
.PARAMETER ValuesToCheck
    The values to check if not all values should be checked
.PARAMETER TurnOffTypeChecking
    Indicates that the type of the parameter should not be checked
#>
function Test-DscParameterState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $CurrentValues,

        [Parameter(Mandatory = $true)]
        [object]
        $DesiredValues,

        [Parameter()]
        [string[]]
        $ValuesToCheck,

        [Parameter()]
        [switch]
        $TurnOffTypeChecking
    )

    $returnValue = $true

    $types = 'System.Management.Automation.PSBoundParametersDictionary', 'System.Collections.Hashtable', 'Microsoft.Management.Infrastructure.CimInstance'

    if ($DesiredValues.GetType().FullName -notin $types)
    {
        throw ("Property 'DesiredValues' in Test-DscParameterState must be either a Hashtable or CimInstance. Type detected was $($DesiredValues.GetType().FullName)")
    }

    if ($DesiredValues -is [Microsoft.Management.Infrastructure.CimInstance] -and -not $ValuesToCheck)
    {
        throw ("If 'DesiredValues' is a CimInstance then property 'ValuesToCheck' must contain a value")
    }

    $desiredValuesClean = Remove-CommonParameter -Hashtable $DesiredValues

    if (-not $ValuesToCheck)
    {
        $keyList = $desiredValuesClean.Keys
    }
    else
    {
        $keyList = $ValuesToCheck
    }

    foreach ($key in $keyList)
    {
        if ($null -ne $desiredValuesClean.$key)
        {
            $desiredType = $desiredValuesClean.$key.GetType()
        }
        else
        {
            $desiredType = [psobject]@{
                Name = 'Unknown'
            }
        }

        if ($null -ne $CurrentValues.$key)
        {
            $currentType = $CurrentValues.$key.GetType()
        }
        else
        {
            $currentType = [psobject]@{
                Name = 'Unknown'
            }
        }

        if ($currentType.Name -ne 'Unknown' -and $desiredType.Name -eq 'PSCredential')
        {
            # This is a credential object. Compare only the user name
            if ($currentType.Name -eq 'PSCredential' -and $CurrentValues.$key.UserName -eq $desiredValuesClean.$key.UserName)
            {
                Write-Verbose -Message ('MATCH: PSCredential username match. Current state is {0} and desired state is {1}' -f $CurrentValues.$key.UserName, $desiredValuesClean.$key.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ('NOTMATCH: PSCredential username mismatch. Current state is {0} and desired state is {1}' -f $CurrentValues.$key.UserName, $desiredValuesClean.$key.UserName)
                $returnValue = $false
            }

            # Assume the string is our username when the matching desired value is actually a credential
            if ($currentType.Name -eq 'string' -and $CurrentValues.$key -eq $desiredValuesClean.$key.UserName)
            {
                Write-Verbose -Message ('MATCH: PSCredential username match. Current state is {0} and desired state is {1}' -f $CurrentValues.$key, $desiredValuesClean.$key.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ('NOTMATCH: PSCredential username mismatch. Current state is {0} and desired state is {1}' -f $CurrentValues.$key, $desiredValuesClean.$key.UserName)
                $returnValue = $false
            }
        }

        if (-not $TurnOffTypeChecking)
        {
            if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and
                $desiredType.FullName -ne $currentType.FullName)
            {
                Write-Verbose -Message "NOTMATCH: Type mismatch for property '$key' Current state type is '$($currentType.Name)' and desired type is '$($desiredType.Name)'"
                continue
            }
        }

        if ($CurrentValues.$key -eq $desiredValuesClean.$key -and -not $desiredType.IsArray)
        {
            Write-Verbose -Message "MATCH: Value (type $($desiredType.Name)) for property '$key' does match. Current state is '$($CurrentValues.$key)' and desired state is '$($desiredValuesClean.$key)'"
            continue
        }

        if ($desiredValuesClean.GetType().Name -in 'HashTable', 'PSBoundParametersDictionary')
        {
            $checkDesiredValue = $desiredValuesClean.ContainsKey($key)
        }
        else
        {
            $checkDesiredValue = Test-DSCObjectHasProperty -Object $desiredValuesClean -PropertyName $key
        }

        if (-not $checkDesiredValue)
        {
            Write-Verbose -Message "MATCH: Value (type $($desiredType.Name)) for property '$key' does match. Current state is '$($CurrentValues.$key)' and desired state is '$($desiredValuesClean.$key)'"
            continue
        }

        if ($desiredType.IsArray)
        {
            Write-Verbose -Message "Comparing values in property '$key'"
            if (-not $CurrentValues.ContainsKey($key) -or -not $CurrentValues.$key)
            {
                Write-Verbose -Message "NOTMATCH: Value (type $($desiredType.Name)) for property '$key' does not match. Current state is '$($CurrentValues.$key)' and desired state is '$($desiredValuesClean.$key)'"
                $returnValue = $false
                continue
            }
            elseif ($CurrentValues.$key.Count -ne $DesiredValues.$key.Count)
            {
                Write-Verbose -Message "NOTMATCH: Value (type $($desiredType.Name)) for property '$key' does have a different count. Current state count is '$($CurrentValues.$key.Count)' and desired state count is '$($desiredValuesClean.$key.Count)'"
                $returnValue = $false
                continue
            }
            else
            {
                $desiredArrayValues = $DesiredValues.$key
                $currentArrayValues = $CurrentValues.$key

                for ($i = 0; $i -lt $desiredArrayValues.Count; $i++)
                {
                    if ($null -ne $desiredArrayValues[$i])
                    {
                        $desiredType = $desiredArrayValues[$i].GetType()
                    }
                    else
                    {
                        $desiredType = [psobject]@{
                            Name = 'Unknown'
                        }
                    }

                    if ($null -ne $currentArrayValues[$i])
                    {
                        $currentType = $currentArrayValues[$i].GetType()
                    }
                    else
                    {
                        $currentType = [psobject]@{
                            Name = 'Unknown'
                        }
                    }

                    if (-not $TurnOffTypeChecking)
                    {
                        if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and
                            $desiredType.FullName -ne $currentType.FullName)
                        {
                            Write-Verbose -Message "`tNOTMATCH: Type mismatch for property '$key' Current state type of element [$i] is '$($currentType.Name)' and desired type is '$($desiredType.Name)'"
                            $returnValue = $false
                            continue
                        }
                    }

                    if ($desiredArrayValues[$i] -ne $currentArrayValues[$i])
                    {
                        Write-Verbose -Message "`tNOTMATCH: Value [$i] (type $($desiredType.Name)) for property '$key' does match. Current state is '$($currentArrayValues[$i])' and desired state is '$($desiredArrayValues[$i])'"
                        $returnValue = $false
                        continue
                    }
                    else
                    {
                        Write-Verbose -Message "`tMATCH: Value [$i] (type $($desiredType.Name)) for property '$key' does match. Current state is '$($currentArrayValues[$i])' and desired state is '$($desiredArrayValues[$i])'"
                        continue
                    }
                }

            }
        }
        else
        {
            if ($desiredValuesClean.$key -ne $CurrentValues.$key)
            {
                Write-Verbose -Message "NOTMATCH: Value (type $($desiredType.Name)) for property '$key' does not match. Current state is '$($CurrentValues.$key)' and desired state is '$($desiredValuesClean.$key)'"
                $returnValue = $false
            }

        }
    }

    Write-Verbose -Message "Result is '$returnValue'"
    return $returnValue
}

<#
.SYNOPSIS
    Tests of an object has a property
.PARAMETER Object
    The object to test
.PARAMETER PropertyName
    The property name
#>
function Test-DSCObjectHasProperty
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [object]
        $Object,

        [Parameter(Mandatory = $true)]
        [string]
        $PropertyName
    )

    if ($Object.PSObject.Properties.Name -contains $PropertyName)
    {
        return [bool] $Object.$PropertyName
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

    $argumentException = New-Object -TypeName 'ArgumentException' `
                                    -ArgumentList @($Message, $ArgumentName)
    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @($argumentException, $ArgumentName, 'InvalidArgument', $null)
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
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' `
                                                -ArgumentList @($Message)
    }
    else
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' `
                                                -ArgumentList @($Message, $ErrorRecord.Exception)
    }

    $newObjectParams = @{
        TypeName = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $invalidOperationException.ToString(), 'MachineStateIncorrect',
                          'InvalidOperation', $null )
    }

    $errorRecordToThrow = New-Object @newObjectParams
    throw $errorRecordToThrow
}

Export-ModuleMember -Function @(
    'Get-LocalizedData'
    'Remove-CommonParameter'
    'Test-DscParameterState'
    'Test-DSCObjectHasProperty'
    'New-InvalidOperationException'
    'New-InvalidArgumentException'
)
