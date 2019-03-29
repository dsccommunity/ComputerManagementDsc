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
        [Parameter(Mandatory = $false)]
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
        $returnCode = $powrprof::PowerSetActiveScheme([System.IntPtr]::Zero,$PowerPlanGuid)

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

Export-ModuleMember -Function `
    Test-DscParameterState, `
    Test-DscObjectHasProperty, `
    Test-Command, `
    Get-TimeZoneId, `
    Test-TimeZoneId, `
    Set-TimeZoneId, `
    Set-TimeZoneUsingDotNet, `
    Get-PowerPlan, `
    Get-ActivePowerPlan, `
    Set-ActivePowerPlan
