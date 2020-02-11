<#
    .SYNOPSIS
        Retrieves the localized string data based on the machine's culture.
        Falls back to en-US strings if the machine's culture is not supported.

    .PARAMETER ResourceName
        The name of the resource as it appears before '.strings.psd1' of the localized string file.
        For example:
            For WindowsOptionalFeature: DSC_WindowsOptionalFeature
            For Service: DSC_ServiceResource
            For Registry: DSC_RegistryResource
            For Helper: SqlServerDscHelper

    .PARAMETER ScriptRoot
        Optional. The root path where to expect to find the culture folder. This is only needed
        for localization in helper modules. This should not normally be used for resources.

    .PARAMETER Postfix
        Optional. The default string to postfix to the resource name to generate the name of the
        localized file.

    .NOTES
        To be able to use localization in the helper function, this function must
        be first in the file, before Get-LocalizedData is used by itself to load
        localized data for this helper module (see directly after this function).
#>
function Get-LocalizedData
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ResourceName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ScriptRoot,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Postfix = 'strings'
    )

    if (-not $ScriptRoot)
    {
        $dscResourcesFolder = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'DSCResources'
        $resourceDirectory = Join-Path -Path $dscResourcesFolder -ChildPath $ResourceName
    }
    else
    {
        $resourceDirectory = $ScriptRoot
    }

    $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath $PSUICulture

    if (-not (Test-Path -Path $localizedStringFileLocation))
    {
        # Fallback to en-US
        $localizedStringFileLocation = Join-Path -Path $resourceDirectory -ChildPath 'en-US'
    }

    Import-LocalizedData `
        -BindingVariable 'localizedData' `
        -FileName "$ResourceName.$Postfix.psd1" `
        -BaseDirectory $localizedStringFileLocation

    return $localizedData
}

<#
    .SYNOPSIS
        Tests if the current machine is a Nano server.
#>
function Test-IsNanoServer
{
    if (Test-Command -Name Get-ComputerInfo -Module 'Microsoft.PowerShell.Management')
    {
        $computerInfo = Get-ComputerInfo

        if ('Server' -eq $computerInfo.OsProductType `
                -and 'NanoServer' -eq $computerInfo.OsServerLevel)
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
        TypeName     = 'System.Management.Automation.ErrorRecord'
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
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter()]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $ErrorRecord)
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
        TypeName     = 'System.Management.Automation.ErrorRecord'
        ArgumentList = @( $invalidOperationException.ToString(), 'MachineStateIncorrect',
            'InvalidOperation', $null )
    }
    $errorRecordToThrow = New-Object @newObjectParams
    throw $errorRecordToThrow
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
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Hashtable
    )

    $inputClone = $Hashtable.Clone()
    $commonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters
    $commonParameters += [System.Management.Automation.PSCmdlet]::OptionalCommonParameters

    $Hashtable.Keys | Where-Object -FilterScript { $_ -in $commonParameters } | ForEach-Object -Process {
        $inputClone.Remove($_)
    }

    return $inputClone
}

<#
    .SYNOPSIS
        Tests the status of DSC resource parameters.

    .DESCRIPTION
        This function tests the parameter status of DSC resource parameters against the current values present on the system.

    .PARAMETER CurrentValues
        A hashtable with the current values on the system, obtained by e.g. Get-TargetResource.

    .PARAMETER DesiredValues
        The hashtable of desired values.

    .PARAMETER ValuesToCheck
        The values to check if not all values should be checked.

    .PARAMETER TurnOffTypeChecking
        Indicates that the type of the parameter should not be checked.

    .PARAMETER ReverseCheck
        Indicates that a reverse check should be done. The current and desired state are swapped for another test.

    .PARAMETER SortArrayValues
        If the sorting of array values does not matter, values are sorted internally before doing the comparison.
#>
function Test-DscParameterState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Object]
        $CurrentValues,

        [Parameter(Mandatory = $true)]
        [System.Object]
        $DesiredValues,

        [Parameter()]
        [System.String[]]
        $ValuesToCheck,

        [Parameter()]
        [switch]
        $TurnOffTypeChecking,

        [Parameter()]
        [switch]
        $ReverseCheck,

        [Parameter()]
        [switch]
        $SortArrayValues
    )

    $returnValue = $true

    if ($CurrentValues -is [Microsoft.Management.Infrastructure.CimInstance] -or
        $CurrentValues -is [Microsoft.Management.Infrastructure.CimInstance[]])
    {
        $CurrentValues = ConvertTo-HashTable -CimInstance $CurrentValues
    }

    if ($DesiredValues -is [Microsoft.Management.Infrastructure.CimInstance] -or
        $DesiredValues -is [Microsoft.Management.Infrastructure.CimInstance[]])
    {
        $DesiredValues = ConvertTo-HashTable -CimInstance $DesiredValues
    }

    $types = 'System.Management.Automation.PSBoundParametersDictionary', 'System.Collections.Hashtable', 'Microsoft.Management.Infrastructure.CimInstance'

    if ($DesiredValues.GetType().FullName -notin $types)
    {
        New-InvalidArgumentException `
            -Message ($script:localizedData.InvalidDesiredValuesError -f $DesiredValues.GetType().FullName) `
            -ArgumentName 'DesiredValues'
    }

    if ($CurrentValues.GetType().FullName -notin $types)
    {
        New-InvalidArgumentException `
            -Message ($script:localizedData.InvalidCurrentValuesError -f $CurrentValues.GetType().FullName) `
            -ArgumentName 'CurrentValues'
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
        $desiredValue = $desiredValuesClean.$key
        $currentValue = $CurrentValues.$key

        if ($desiredValue -is [Microsoft.Management.Infrastructure.CimInstance] -or
            $desiredValue -is [Microsoft.Management.Infrastructure.CimInstance[]])
        {
            $desiredValue = ConvertTo-HashTable -CimInstance $desiredValue
        }
        if ($currentValue -is [Microsoft.Management.Infrastructure.CimInstance] -or
            $currentValue -is [Microsoft.Management.Infrastructure.CimInstance[]])
        {
            $currentValue = ConvertTo-HashTable -CimInstance $currentValue
        }

        if ($null -ne $desiredValue)
        {
            $desiredType = $desiredValue.GetType()
        }
        else
        {
            $desiredType = @{
                Name = 'Unknown'
            }
        }

        if ($null -ne $currentValue)
        {
            $currentType = $currentValue.GetType()
        }
        else
        {
            $currentType = @{
                Name = 'Unknown'
            }
        }

        if ($currentType.Name -ne 'Unknown' -and $desiredType.Name -eq 'PSCredential')
        {
            # This is a credential object. Compare only the user name
            if ($currentType.Name -eq 'PSCredential' -and $currentValue.UserName -eq $desiredValue.UserName)
            {
                Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $currentValue.UserName, $desiredValue.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $currentValue.UserName, $desiredValue.UserName)
                $returnValue = $false
            }

            # Assume the string is our username when the matching desired value is actually a credential
            if ($currentType.Name -eq 'string' -and $currentValue -eq $desiredValue.UserName)
            {
                Write-Verbose -Message ($script:localizedData.MatchPsCredentialUsernameMessage -f $currentValue, $desiredValue.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.NoMatchPsCredentialUsernameMessage -f $currentValue, $desiredValue.UserName)
                $returnValue = $false
            }
        }

        if (-not $TurnOffTypeChecking)
        {
            if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and
                $desiredType.FullName -ne $currentType.FullName)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchTypeMismatchMessage -f $key, $currentType.FullName, $desiredType.FullName)
                $returnValue = $false
                continue
            }
        }

        if ($currentValue -eq $desiredValue -and -not $desiredType.IsArray)
        {
            Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
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
            Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
            continue
        }

        if ($desiredType.IsArray)
        {
            Write-Verbose -Message ($script:localizedData.TestDscParameterCompareMessage -f $key, $desiredType.FullName)

            if (-not $currentValue -and -not $desiredValue)
            {
                Write-Verbose -Message ($script:localizedData.MatchValueMessage -f $desiredType.FullName, $key, 'empty array', 'empty array')
                continue
            }
            elseif (-not $currentValue)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
                $returnValue = $false
                continue
            }
            elseif ($currentValue.Count -ne $desiredValue.Count)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchValueDifferentCountMessage -f $desiredType.FullName, $key, $currentValue.Count, $desiredValue.Count)
                $returnValue = $false
                continue
            }
            else
            {
                $desiredArrayValues = $desiredValue
                $currentArrayValues = $currentValue

                if ($SortArrayValues)
                {
                    $desiredArrayValues = $desiredArrayValues | Sort-Object
                    $currentArrayValues = $currentArrayValues | Sort-Object
                }

                for ($i = 0; $i -lt $desiredArrayValues.Count; $i++)
                {
                    if ($null -ne $desiredArrayValues[$i])
                    {
                        $desiredType = $desiredArrayValues[$i].GetType()
                    }
                    else
                    {
                        $desiredType = @{
                            Name = 'Unknown'
                        }
                    }

                    if ($null -ne $currentArrayValues[$i])
                    {
                        $currentType = $currentArrayValues[$i].GetType()
                    }
                    else
                    {
                        $currentType = @{
                            Name = 'Unknown'
                        }
                    }

                    if (-not $TurnOffTypeChecking)
                    {
                        if (($desiredType.Name -ne 'Unknown' -and $currentType.Name -ne 'Unknown') -and
                            $desiredType.FullName -ne $currentType.FullName)
                        {
                            Write-Verbose -Message ($script:localizedData.NoMatchElementTypeMismatchMessage -f $key, $i, $currentType.FullName, $desiredType.FullName)
                            $returnValue = $false
                            continue
                        }
                    }

                    if ($desiredArrayValues[$i] -ne $currentArrayValues[$i])
                    {
                        Write-Verbose -Message ($script:localizedData.NoMatchElementValueMismatchMessage -f $i, $desiredType.FullName, $key, $currentArrayValues[$i], $desiredArrayValues[$i])
                        $returnValue = $false
                        continue
                    }
                    else
                    {
                        Write-Verbose -Message ($script:localizedData.MatchElementValueMessage -f $i, $desiredType.FullName, $key, $currentArrayValues[$i], $desiredArrayValues[$i])
                        continue
                    }
                }

            }
        }
        elseif ($desiredType -eq [System.Collections.Hashtable] -and $currentType -eq [System.Collections.Hashtable])
        {
            $param = $PSBoundParameters
            $param.CurrentValues = $currentValue
            $param.DesiredValues = $desiredValue
            $null = $param.Remove('ValuesToCheck')

            if ($returnValue)
            {
                $returnValue = Test-DscParameterState @param
            }
            else
            {
                Test-DscParameterState @param | Out-Null
            }
            continue
        }
        else
        {
            if ($desiredValue -ne $currentValue)
            {
                Write-Verbose -Message ($script:localizedData.NoMatchValueMessage -f $desiredType.FullName, $key, $currentValue, $desiredValue)
                $returnValue = $false
            }
        }
    }

    if ($ReverseCheck)
    {
        Write-Verbose -Message $script:localizedData.StartingReverseCheck
        $reverseCheckParameters = $PSBoundParameters
        $reverseCheckParameters.CurrentValues = $DesiredValues
        $reverseCheckParameters.DesiredValues = $CurrentValues
        $null = $reverseCheckParameters.Remove('ReverseCheck')

        if ($returnValue)
        {
            $returnValue = Test-DscParameterState @reverseCheckParameters
        }
        else
        {
            $null = Test-DscParameterState @reverseCheckParameters
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
        Converts a hashtable into a CimInstance array.

    .DESCRIPTION
        This function is used to convert a hashtable into MSFT_KeyValuePair objects. These are stored as an CimInstance array.
        DSC cannot handle hashtables but CimInstances arrays storing MSFT_KeyValuePair.

    .PARAMETER Hashtable
        A hashtable with the values to convert.

    .OUTPUTS
        An object array with CimInstance objects.
#>
function ConvertTo-CimInstance
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Collections.Hashtable]
        $Hashtable
    )

    process
    {
        foreach ($item in $Hashtable.GetEnumerator())
        {
            New-CimInstance -ClassName MSFT_KeyValuePair -Namespace root/microsoft/Windows/DesiredStateConfiguration -Property @{
                Key   = $item.Key
                Value = if ($item.Value -is [array])
                {
                    $item.Value -join ','
                }
                else
                {
                    $item.Value
                }
            } -ClientOnly
        }
    }
}

<#
    .SYNOPSIS
        Converts CimInstances into a hashtable.

    .DESCRIPTION
        This function is used to convert a CimInstance array containing MSFT_KeyValuePair objects into a hashtable.

    .PARAMETER CimInstance
        An array of CimInstances or a single CimInstance object to convert.

    .OUTPUTS
        Hashtable
#>
function ConvertTo-HashTable
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $CimInstance
    )

    begin
    {
        $result = @{ }
    }

    process
    {
        foreach ($ci in $CimInstance)
        {
            $result.Add($ci.Key, $ci.Value)
        }
    }

    end
    {
        $result
    }
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
        Write-Verbose -Message ($script:localizedData.GettingTimeZoneMessage -f 'Cmdlets')

        $timeZone = (Get-TimeZone).StandardName
    }
    else
    {
        Write-Verbose -Message ($script:localizedData.GettingTimeZoneMessage -f 'CIM')

        $timeZone = (Get-CimInstance `
                -ClassName Win32_TimeZone `
                -Namespace root\cimv2).StandardName
    }

    Write-Verbose -Message ($script:localizedData.CurrentTimeZoneMessage -f $timeZone)

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
            Write-Verbose -Message ($script:localizedData.SettingTimeZoneMessage -f $TimeZoneId, '.NET')

            Set-TimeZoneUsingDotNet -TimeZoneId $TimeZoneId
        }
        else
        {
            # For anything else use TZUTIL.EXE.
            Write-Verbose -Message ($script:localizedData.SettingTimeZoneMessage -f $TimeZoneId, 'TZUTIL.EXE')

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

    Write-Verbose -Message ($script:localizedData.TimeZoneUpdatedMessage -f $TimeZoneId)
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
        Write-Verbose -Message ($script:localizedData.AddingSetTimeZoneDotNetTypeMessage)

        $setTimeZoneCs = Get-Content `
            -Path (Join-Path -Path $PSScriptRoot -ChildPath 'SetTimeZone.cs') `
            -Raw

        Add-Type `
            -Language CSharp `
            -TypeDefinition $setTimeZoneCs
    } # if

    [Microsoft.PowerShell.TimeZone.TimeZone]::Set($TimeZoneId)
} # function Set-TimeZoneUsingDotNet

<#
    .SYNOPSIS
        This function gets a specific power plan or all available power plans.
        The function returns one or more hashtable(s) containing
        the friendly name and GUID of the power plan(s).

    .PARAMETER PowerPlan
        Friendly name or GUID of a power plan to get.
        When not specified the function will return all available power plans.

    .NOTES
        This function is used by the PowerPlan resource.
#>
function Get-PowerPlan
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    param
    (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $PowerPlan
    )

    $ErrorActionPreference = 'Stop'

    # Get all available power plan(s) as a hashtable with friendly name and GUID
    $allAvailablePowerPlans = Get-PowerPlanUsingPInvoke

    # If a specific power plan is specified filter for it otherwise return all
    if ($PSBoundParameters.ContainsKey('PowerPlan'))
    {
        $selectedPowerPlan = $allAvailablePowerPlans | Where-Object -FilterScript {
            ($_.FriendlyName -eq $PowerPlan) -or
            ($_.Guid -eq $PowerPlan)
        }

        return $selectedPowerPlan
    }
    else
    {
        return $allAvailablePowerPlans
    }
}

<#
    .SYNOPSIS
        This function gets the friendly name of a power plan specified by its GUID.

    .PARAMETER PowerPlanGuid
        The GUID of a power plan.

    .NOTES
        This function uses Platform Invoke (P/Invoke) mechanism to call native Windows APIs
        because the Win32_PowerPlan WMI class has issues on some platforms or is unavailable at all.
        e.g Server 2012 R2 core or Nano Server.
        This function is used by the Get-PowerPlan function.
#>
function Get-PowerPlanFriendlyName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Guid]
        $PowerPlanGuid
    )

    $ErrorActionPreference = 'Stop'

    # Define C# signature of PowerReadFriendlyName function
    $MethodDefinition = @'
        [DllImport("powrprof.dll", CharSet = CharSet.Unicode)]
        public static extern uint PowerReadFriendlyName(
            IntPtr RootPowerKey,
            Guid SchemeGuid,
            IntPtr SubGroupOfPowerSettingGuid,
            IntPtr PowerSettingGuid,
            IntPtr Buffer,
            ref uint BufferSize
        );
'@

    # Create Win32PowerReadFriendlyName object with the static method PowerReadFriendlyName.
    $powerprof = Add-Type `
        -MemberDefinition $MethodDefinition `
        -Name 'Win32PowerReadFriendlyName' `
        -Namespace 'Win32Functions' `
        -PassThru

    # Define variable for buffer size which whe have frist to figure out.
    $bufferSize = 0
    $returnCode = 0

    try
    {
        <#
            Frist get needed buffer size by calling PowerReadFriendlyName
            with NULL value for 'Buffer' parameter to get the required buffer size.
        #>
        $returnCode = $powerprof::PowerReadFriendlyName(
            [System.IntPtr]::Zero,
            $PowerPlanGuid,
            [System.IntPtr]::Zero,
            [System.IntPtr]::Zero,
            [System.IntPtr]::Zero,
            [ref]$bufferSize)

        if ($returnCode -eq 0)
        {
            try
            {
                # Now lets allocate the needed buffer size
                $ptrName = [System.Runtime.InteropServices.Marshal]::AllocHGlobal([System.Int32]$bufferSize)

                <#
                    Get the actual friendly name of the powerlan by calling PowerReadFriendlyName again.
                    This time with the correct buffer size for the 'Buffer' parameter.
                #>
                $returnCode = $powerprof::PowerReadFriendlyName(
                    [System.IntPtr]::Zero,
                    $PowerPlanGuid,
                    [System.IntPtr]::Zero,
                    [System.IntPtr]::Zero,
                    $ptrName,
                    [ref]$bufferSize)

                if ($returnCode -eq 0)
                {
                    # Create a managed String object form the unmanged memory block.
                    $friendlyName = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptrName)
                    return $friendlyName
                }
                else
                {
                    throw [ComponentModel.Win32Exception]::new([System.Int32]$returnCode)
                }
            }
            finally
            {
                # Make sure allocated memory is freed up again.
                [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptrName)
            }
        }
        else
        {
            throw [ComponentModel.Win32Exception]::new([System.Int32]$returnCode)
        }
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.UnableToGetPowerSchemeFriendlyName -f $PowerPlanGuid, $_.Exception.NativeErrorCode, $_.Exception.Message)
    }
}

<#
    .SYNOPSIS
        This function gets the GUID of the currently active power plan.

    .NOTES
        This function uses Platform Invoke (P/Invoke) mechanism to call native Windows APIs
        because the Win32_PowerPlan WMI class has issues on some platforms or is unavailable at all.
        e.g Server 2012 R2 core or Nano Server.
        This function is used by the PowerPlan resource.
#>
function Get-ActivePowerPlan
{
    [CmdletBinding()]
    [OutputType([System.Guid])]
    param
    (
    )

    $ErrorActionPreference = 'Stop'

    # Define C# signature of PowerGetActiveScheme function
    $powerGetActiveSchemeDefinition = @'
        [DllImport("powrprof.dll", CharSet = CharSet.Unicode)]
        public static extern uint PowerGetActiveScheme(IntPtr UserRootPowerKey, ref IntPtr ActivePolicyGuid);
'@

    $returnCode = 0

    # Create Win32PowerGetActiveScheme object with the static method PowerGetActiveScheme
    $powrprof = Add-Type `
        -MemberDefinition $powerGetActiveSchemeDefinition `
        -Name 'Win32PowerGetActiveScheme' `
        -Namespace 'Win32Functions' `
        -PassThru

    try
    {
        # Get the GUID of the active power scheme
        $activeSchemeGuid = [System.IntPtr]::Zero
        $returnCode = $powrprof::PowerGetActiveScheme([System.IntPtr]::Zero, [ref]$activeSchemeGuid)

        # Check for non 0 return codes / errors form the native function
        if ($returnCode -ne 0)
        {
            # Create a Win32Exception object out of the return code
            $win32Exception = ([ComponentModel.Win32Exception]::new([System.Int32]$returnCode))
            New-InvalidOperationException `
                -Message ($script:localizedData.FailedToGetActivePowerScheme -f $win32Exception.NativeErrorCode, $win32Exception.Message)
        }

        # Create a managed Guid object form the unmanged memory block and return it
        return [System.Runtime.InteropServices.Marshal]::PtrToStructure($activeSchemeGuid, [System.Type][System.Guid])
    }
    finally
    {
        # Make sure allocated memory is freed up again.
        [System.Runtime.InteropServices.Marshal]::FreeHGlobal($activeSchemeGuid)
    }
}

<#
    .SYNOPSIS
        This function enumerates all available power plans/schemes.
        The function returns one or more hashtable(s) containing
        the friendly name and GUID of the power plan(s).

    .NOTES
        This function uses Platform Invoke (P/Invoke) mechanism to call native Windows APIs
        because the Win32_PowerPlan WMI class has issues on some platforms or is unavailable at all.
        e.g Server 2012 R2 core or Nano Server.
        This function is used by the PowerPlan resource.
#>
function Get-PowerPlanUsingPInvoke
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable[]])]
    param
    (
    )

    $ErrorActionPreference = 'Stop'

    Write-Verbose -Message ($script:localizedData.EnumeratingPowerPlans)

    # Define C# signature of PowerEnumerate function
    $powerEnumerateDefinition = @'
        [DllImport("powrprof.dll", CharSet = CharSet.Unicode)]
        public static extern uint PowerEnumerate(
            IntPtr RootPowerKey,
            IntPtr SchemeGuid,
            IntPtr SubGroupOfPowerSetting,
            int AccessFlags,
            uint Index,
            IntPtr rBuffer,
            ref uint BufferSize
        );
'@

    # Create Win32PowerEnumerate object with the static method PowerEnumerate
    $powrprof = Add-Type `
        -MemberDefinition $powerEnumerateDefinition `
        -Name 'Win32PowerEnumerate' `
        -Namespace 'Win32Functions' `
        -PassThru

    $index = 0
    $returnCode = 0
    $allAvailablePowerPlans = [System.Collections.ArrayList]::new()

    # PowerEnumerate returns the GUID of the powerplan(s). Guid = 16 Bytes.
    $bufferSize = 16

    <#
        The PowerEnumerate function returns only one guid at a time.
        So we have to loop here until error code 259 (no more data) is returned to get all power plan GUIDs.
    #>
    while ($returnCode -ne 259)
    {
        try
        {
            # Allocate buffer
            $readBuffer = [System.Runtime.InteropServices.Marshal]::AllocHGlobal([System.Int32]$bufferSize)

            # Get Guid of the power plan using the native PowerEnumerate function
            $returnCode = $powrprof::PowerEnumerate([System.IntPtr]::Zero, [System.IntPtr]::Zero, [System.IntPtr]::Zero, 16, $index, $readBuffer, [ref]$bufferSize)

            # Return Code 259 means no more data so we stop here.
            if ($returnCode -eq 259)
            {
                break
            }

            # Check for non 0 return codes / errors form the native function.
            if ($returnCode -ne 0)
            {
                # Create a Win32Exception object out of the return code
                $win32Exception = ([ComponentModel.Win32Exception]::new([System.Int32]$returnCode))
                New-InvalidOperationException `
                    -Message ($script:localizedData.UnableToEnumeratingPowerSchemes -f $win32Exception.NativeErrorCode, $win32Exception.Message)
            }

            # Create a managed Guid object form the unmanaged memory block
            $planGuid = [System.Runtime.InteropServices.Marshal]::PtrToStructure($readBuffer, [System.Type][System.Guid])

            Write-Verbose -Message ($script:localizedData.PowerPlanFound -f $planGuid)

            # Now get the friendly name of to the power plan
            $planFriendlyName = Get-PowerPlanFriendlyName -PowerPlanGuid $planGuid

            Write-Verbose -Message ($script:localizedData.PowerPlanFriendlyNameFound -f $planFriendlyName)

            $null = $allAvailablePowerPlans.Add(
                @{
                    FriendlyName = $planFriendlyName
                    Guid         = $planGuid
                }
            )

            $index++
        }
        finally
        {
            # Free up memory
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($readBuffer)
        }
    }

    Write-Verbose -Message ($script:localizedData.AllPowerPlansFound)

    return $allAvailablePowerPlans
}

<#
    .SYNOPSIS
        This function activates a specific power plan (specified by its GUID).

    .PARAMETER Guid
        GUID of a power plan to activate.

    .NOTES
        This function uses Platform Invoke (P/Invoke) mechanism to call native Windows APIs
        because the Win32_PowerPlan WMI class has on some platforms issues or is unavailable at all.
        e.g Server 2012 R2 core or Nano Server.
        This function is used by the Get-PowerPlan function respectively the PowerPlan resource.
#>
function Set-ActivePowerPlan
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Guid]
        $PowerPlanGuid
    )

    $ErrorActionPreference = 'Stop'

    # Define C# signature of PowerSetActiveScheme function
    $powerSetActiveSchemeDefinition = @'
        [DllImport("powrprof.dll", CharSet = CharSet.Auto)]
        public static extern uint PowerSetActiveScheme(
            IntPtr RootPowerKey,
            Guid SchemeGuid
        );
'@

    # Create Win32PowerSetActiveScheme object with the static method PowerSetActiveScheme.
    $powrprof = Add-Type `
        -MemberDefinition $powerSetActiveSchemeDefinition `
        -Name 'Win32PowerSetActiveScheme' `
        -Namespace 'Win32Functions' `
        -PassThru

    try
    {
        # Set the active power scheme with the native function
        $returnCode = $powrprof::PowerSetActiveScheme([System.IntPtr]::Zero, $PowerPlanGuid)

        # Check for non 0 return codes / errors form the native function
        if ($returnCode -ne 0)
        {
            throw [ComponentModel.Win32Exception]::new([int]$returnCode)
        }
    }
    catch
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.FailedToSetActivePowerScheme -f $PowerPlanGuid, $_.Exception.NativeErrorCode, $_.Exception.Message)
    }
}

<#
    .SYNOPSIS
        Returns the value of the provided in the Name parameter, at the registry
        location provided in the Path parameter.

    .PARAMETER Path
        String containing the path in the registry to the property name.

    .PARAMETER PropertyName
        String containing the name of the property for which the value is returned.
#>
function Get-RegistryPropertyValue
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    $getItemPropertyParameters = @{
        Path = $Path
        Name = $Name
    }

    <#
        Using a try/catch block instead of 'SilentlyContinue' to be
        able to unit test a failing registry path.
    #>
    try
    {
        $getItemPropertyResult = (Get-ItemProperty @getItemPropertyParameters -ErrorAction Stop).$Name
    }
    catch
    {
        $getItemPropertyResult = $null
    }

    return $getItemPropertyResult
}

<#
    .SYNOPSIS
        Throws an error if there is a bound parameter that exists in both the
        mutually exclusive lists.

    .PARAMETER BoundParameterList
        The parameters that should be evaluated against the mutually exclusive
        lists MutuallyExclusiveList1 and MutuallyExclusiveList2. This parameter is
        normally set to the $PSBoundParameters variable.

    .PARAMETER MutuallyExclusiveList1
        An array of parameter names that are not allowed to be bound at the
        same time and those in MutuallyExclusiveList2.

    .PARAMETER MutuallyExclusiveList2
        An array of parameter names that are not allowed to be bound at the
        same time and those in MutuallyExclusiveList1.
#>
function Assert-BoundParameter
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Hashtable]
        $BoundParameterList,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $MutuallyExclusiveList1,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $MutuallyExclusiveList2
    )

    $itemFoundFromList1 = $BoundParameterList.Keys.Where({ $_ -in $MutuallyExclusiveList1 })
    $itemFoundFromList2 = $BoundParameterList.Keys.Where({ $_ -in $MutuallyExclusiveList2 })

    if ($itemFoundFromList1.Count -gt 0 -and $itemFoundFromList2.Count -gt 0)
    {
        $errorMessage = `
            $script:localizedData.ParameterUsageWrong `
                -f ($MutuallyExclusiveList1 -join "','"), ($MutuallyExclusiveList2 -join "','")

        New-InvalidArgumentException -ArgumentName 'Parameters' -Message $errorMessage
    }
}

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'ComputerManagementDsc.Common' `
    -ScriptRoot $PSScriptRoot

Export-ModuleMember -Function @(
    'Test-DscParameterState'
    'Test-DscObjectHasProperty'
    'Test-Command'
    'Get-TimeZoneId'
    'Test-TimeZoneId'
    'Set-TimeZoneId'
    'Set-TimeZoneUsingDotNet'
    'Get-PowerPlan'
    'Get-ActivePowerPlan'
    'Set-ActivePowerPlan'
    'Test-IsNanoServer'
    'New-InvalidArgumentException'
    'New-InvalidOperationException'
    'Get-LocalizedData'
    'Get-RegistryPropertyValue'
    'Assert-BoundParameter'
)
