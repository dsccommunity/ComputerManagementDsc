# Import the ComputerManagement Resource Helper Module
Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.ResourceHelper' `
            -ChildPath 'ComputerManagementDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'ComputerManagementDsc.Common' `
    -ResourcePath $PSScriptRoot

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
        [System.Object]
        $DesiredValues,

        [Parameter()]
        [System.String[]]
        $ValuesToCheck,

        [Parameter()]
        [switch]
        $TurnOffTypeChecking
    )

    $returnValue = $true

    $types = 'System.Management.Automation.PSBoundParametersDictionary', 'System.Collections.Hashtable', 'Microsoft.Management.Infrastructure.CimInstance'

    if ($DesiredValues.GetType().FullName -notin $types)
    {
        New-InvalidArgumentException `
            -Message ($script:localizedData.InvalidDesiredValuesError -f $DesiredValues.GetType().FullName) `
            -ArgumentName 'DesiredValues'
    }

    if ($DesiredValues -is [Microsoft.Management.Infrastructure.CimInstance] -and -not $ValuesToCheck)
    {
        New-InvalidArgumentException `
            -Message $script:localizedData.InvalidValuesToCheckError `
            -ArgumentName 'ValuesToCheck'
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
            $desiredType = [psobject] @{
                Name = 'Unknown'
            }
        }

        if ($null -ne $CurrentValues.$key)
        {
            $currentType = $CurrentValues.$key.GetType()
        }
        else
        {
            $currentType = [psobject] @{
                Name = 'Unknown'
            }
        }

        if ($currentType.Name -ne 'Unknown' -and $desiredType.Name -eq 'PSCredential')
        {
            # This is a credential object. Compare only the user name
            if ($currentType.Name -eq 'PSCredential' -and $CurrentValues.$key.UserName -eq $desiredValuesClean.$key.UserName)
            {
                Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $CurrentValues.$key.UserName, $desiredValuesClean.$key.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $CurrentValues.$key.UserName, $desiredValuesClean.$key.UserName)
                $returnValue = $false
            }

            # Assume the string is our username when the matching desired value is actually a credential
            if ($currentType.Name -eq 'string' -and $CurrentValues.$key -eq $desiredValuesClean.$key.UserName)
            {
                Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $CurrentValues.$key, $desiredValuesClean.$key.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $CurrentValues.$key, $desiredValuesClean.$key.UserName)
                $returnValue = $false
            }
        }

        if (-not $TurnOffTypeChecking)
        {
            if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and
                $desiredType.FullName -ne $currentType.FullName)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchTypeMismatchMessage -f $key, $currentType.Name, $desiredType.Name)
                continue
            }
        }

        if ($CurrentValues.$key -eq $desiredValuesClean.$key -and -not $desiredType.IsArray)
        {
            Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.Name, $key, $CurrentValues.$key, $desiredValuesClean.$key)
            continue
        }

        if ($desiredValuesClean.GetType().Name -in 'HashTable', 'PSBoundParametersDictionary')
        {
            $checkDesiredValue = $desiredValuesClean.ContainsKey($key)
        }
        else
        {
            $checkDesiredValue = Test-DscObjectHasProperty -Object $desiredValuesClean -PropertyName $key
        }

        if (-not $checkDesiredValue)
        {
            Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.Name, $key, $CurrentValues.$key, $desiredValuesClean.$key)
            continue
        }

        if ($desiredType.IsArray)
        {
            Write-Verbose -Message ($script:localizedData.TestDscParameterCompareMessage -f $key)

            if (-not $CurrentValues.ContainsKey($key) -or -not $CurrentValues.$key)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchValueMessage -f $desiredType.Name, $key, $CurrentValues.$key, $desiredValuesClean.$key)
                $returnValue = $false
                continue
            }
            elseif ($CurrentValues.$key.Count -ne $DesiredValues.$key.Count)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchValueDifferentCountMessage -f $desiredType.Name, $key, $CurrentValues.$key.Count, $desiredValuesClean.$key.Count)
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
                            Write-Verbose -Message ($script:localizedData.NoMatchElementTypeMismatchMessage -f $key, $i, $currentType.Name, $desiredType.Name)
                            $returnValue = $false
                            continue
                        }
                    }

                    if ($desiredArrayValues[$i] -ne $currentArrayValues[$i])
                    {
                        Write-Verbose -Message ($script:localizedData.NoMatchElementValueMismatchMessage -f $i, $desiredType.Name, $key, $currentArrayValues[$i], $desiredArrayValues[$i])
                        $returnValue = $false
                        continue
                    }
                    else
                    {
                        Write-Verbose -Message ($script:localizedData.MatchElementValueMessage -f $i, $desiredType.Name, $key, $currentArrayValues[$i], $desiredArrayValues[$i])
                        continue
                    }
                }

            }
        }
        else
        {
            if ($desiredValuesClean.$key -ne $CurrentValues.$key)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchValueMessage -f $desiredType.Name, $key, $CurrentValues.$key, $desiredValuesClean.$key)
                $returnValue = $false
            }
        }
    }

    Write-Verbose -Message ($script:localizedData.TestDscParameterResultMessage -f $returnValue)
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
function Test-DscObjectHasProperty
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $Object,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PropertyName
    )

    if ($Object.PSObject.Properties.Name -contains $PropertyName)
    {
        return [System.Boolean] $Object.$PropertyName
    }

    return $false
}

<#
    .SYNOPSIS
        This function tests if a cmdlet exists.

    .PARAMETER Name
        The name of the cmdlet to check for.

    .PARAMETER Module
        The module containing the command.
#>
function Test-Command
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Module
    )

    return ($null -ne (Get-Command @PSBoundParameters -ErrorAction SilentlyContinue))
} # function Test-Command

<#
    .SYNOPSIS
        Get the of the current time zone Id.

    .NOTES
        This function is also used by ScheduledTask integration tests.
#>
function Get-TimeZoneId
{
    [CmdletBinding()]
    param
    (
    )

    if (Test-Command -Name 'Get-TimeZone' -Module 'Microsoft.PowerShell.Management')
    {
        Write-Verbose -Message ($LocalizedData.GettingTimeZoneMessage -f 'Cmdlets')

        $timeZone = (Get-TimeZone).StandardName
    }
    else
    {
        Write-Verbose -Message ($LocalizedData.GettingTimeZoneMessage -f 'CIM')

        $timeZone = (Get-CimInstance `
                -ClassName Win32_TimeZone `
                -Namespace root\cimv2).StandardName
    }

    Write-Verbose -Message ($LocalizedData.CurrentTimeZoneMessage -f $timeZone)

    $timeZoneInfo = [System.TimeZoneInfo]::GetSystemTimeZones() |
        Where-Object -Property StandardName -EQ $timeZone

    return $timeZoneInfo.Id
} # function Get-TimeZoneId

<#
    .SYNOPSIS
        Compare a time zone Id with the current time zone Id.

    .PARAMETER TimeZoneId
        The Id of the time zone to compare with the current time zone.

    .NOTES
        This function is also used by ScheduledTask integration tests.
#>
function Test-TimeZoneId
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TimeZoneId
    )

    # Test if the expected value is the same as the current value.
    $currentTimeZoneId = Get-TimeZoneId

    return $TimeZoneId -eq $currentTimeZoneId
} # function Test-TimeZoneId

<#
    .SYNOPSIS
        Sets the current time zone using a time zone Id.

    .PARAMETER TimeZoneId
        The Id of the time zone to set.

    .NOTES
        This function is also used by ScheduledTask integration tests.
#>
function Set-TimeZoneId
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TimeZoneId
    )

    if (Test-Command -Name 'Set-TimeZone' -Module 'Microsoft.PowerShell.Management')
    {
        Set-TimeZone -Id $TimeZoneId
    }
    else
    {
        if (Test-Command -Name 'Add-Type' -Module 'Microsoft.Powershell.Utility')
        {
            # We can use reflection to modify the time zone.
            Write-Verbose -Message ($LocalizedData.SettingTimeZoneMessage -f $TimeZoneId, '.NET')

            Set-TimeZoneUsingDotNet -TimeZoneId $TimeZoneId
        }
        else
        {
            # For anything else use TZUTIL.EXE.
            Write-Verbose -Message ($LocalizedData.SettingTimeZoneMessage -f $TimeZoneId, 'TZUTIL.EXE')

            try
            {
                & tzutil.exe @('/s', $TimeZoneId)
            }
            catch
            {
                Write-Verbose -Message $_.Exception.Message
            } # try
        } # if
    } # if

    Write-Verbose -Message ($LocalizedData.TimeZoneUpdatedMessage -f $TimeZoneId)
} # function Set-TimeZoneId

<#
    .SYNOPSIS
        This function sets the time zone on the machine using .NET reflection.
        It exists so that the ::Set method can be mocked by Pester.

    .PARAMETER TimeZoneId
        The Id of the time zone to set using .NET.

    .NOTES
        This function is also used by ScheduledTask integration tests.
#>
function Set-TimeZoneUsingDotNet
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $TimeZoneId
    )

    # Add the [TimeZoneHelper.TimeZone] type if it is not defined.
    if (-not ([System.Management.Automation.PSTypeName] 'TimeZoneHelper.TimeZone').Type)
    {
        Write-Verbose -Message ($LocalizedData.AddingSetTimeZoneDotNetTypeMessage)

        $setTimeZoneCs = Get-Content `
            -Path (Join-Path -Path $PSScriptRoot -ChildPath 'SetTimeZone.cs') `
            -Raw

        Add-Type `
            -Language CSharp `
            -TypeDefinition $setTimeZoneCs
    } # if

    [Microsoft.PowerShell.TimeZone.TimeZone]::Set($TimeZoneId)
} # function Set-TimeZoneUsingDotNet

Export-ModuleMember -Function `
    Test-DscParameterState, `
    Test-DscObjectHasProperty, `
    Test-Command, `
    Get-TimeZoneId, `
    Test-TimeZoneId, `
    Set-TimeZoneId, `
    Set-TimeZoneUsingDotNet
