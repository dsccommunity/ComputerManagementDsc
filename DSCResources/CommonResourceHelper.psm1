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

function Remove-CommonParameter
{
    [OutputType([hashtable])]
    [cmdletbinding()]
    param
    (
        [Parameter(Mandatory)]
        [hashtable]
        $Hashtable
    )

    $inputClone = $Hashtable.Clone()
    $commonParameters = [System.Management.Automation.PSCmdlet]::CommonParameters
    $commonParameters += [System.Management.Automation.PSCmdlet]::OptionalCommonParameters

    $Hashtable.Keys | Where-Object { $_ -in $commonParameters } | ForEach-Object {
        $inputClone.Remove($_)
    }

    $inputClone
}

function Test-DscParameterState
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)] 
        [hashtable]
        $CurrentValues,

        [Parameter(Mandatory)] 
        [object]
        $DesiredValues,
        
        [string[]]
        $ValuesToCheck,
        
        [switch]$TurnOffTypeChecking
    )

    $returnValue = $true

    $types = 'System.Management.Automation.PSBoundParametersDictionary', 'System.Collections.Hashtable', 'Microsoft.Management.Infrastructure.CimInstance'
    
    if ($DesiredValues.GetType().FullName -notin $types)
    {
        throw ("Property 'DesiredValues' in Test-DscParameterState must be either a Hashtable or CimInstance. Type detected was $($DesiredValues.GetType().Name)")
    }

    if ($DesiredValues.GetType().FullName -eq 'Microsoft.Management.Infrastructure.CimInstance' -and -not $ValuesToCheck)
    {
        throw ("If 'DesiredValues' is a CimInstance then property 'ValuesToCheck' must contain a value")
    }
    
    $DesiredValuesClean = Remove-CommonParameter -Hashtable $DesiredValues

    if (-not $ValuesToCheck)
    {
        $keyList = $DesiredValuesClean.Keys
    } 
    else
    {
        $keyList = $ValuesToCheck
    }

    foreach ($key in $keyList)
    {
        if ($null -ne $DesiredValuesClean.$key)
        {
            $desiredType = $DesiredValuesClean.$key.GetType()
        }
        else
        {
            $desiredType = [psobject]@{ Name = 'Unknown' }
        }
        
        if ($null -ne $CurrentValues.$key)
        {
            $currentType = $CurrentValues.$key.GetType()
        }
        else
        {
            $currentType = [psobject]@{ Name = 'Unknown' }
        }

        if ($currentType.Name -ne 'Unknown' -and $desiredType.Name -eq 'PSCredential')
        {
            # This is a credential object. Compare only the user name
            if ($currentType.Name -eq 'PSCredential' -and $CurrentValues.$key.UserName -eq $DesiredValuesClean.$key.UserName)
            {
                Write-Verbose -Message ('MATCH: PSCredential username match. Current state is {0} and desired state is {1}' -f $CurrentValues.$key.UserName, $DesiredValuesClean.$key.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ('NOTMATCH: PSCredential username mismatch. Current state is {0} and desired state is {1}' -f $CurrentValues.$key.UserName, $DesiredValuesClean.$key.UserName)
                $returnValue = $false
            }
            
            # Assume the string is our username when the matching desired value is actually a credential
            if($currentType.Name -eq 'string' -and $CurrentValues.$key -eq $DesiredValuesClean.$key.UserName)
            {
                Write-Verbose -Message ('MATCH: PSCredential username match. Current state is {0} and desired state is {1}' -f $CurrentValues.$key, $DesiredValuesClean.$key.UserName)
                continue
            }
            else
            {
                Write-Verbose -Message ('NOTMATCH: PSCredential username mismatch. Current state is {0} and desired state is {1}' -f $CurrentValues.$key, $DesiredValuesClean.$key.UserName)
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

        if ($CurrentValues.$key -eq $DesiredValuesClean.$key -and -not $desiredType.IsArray)
        {
            Write-Verbose -Message "MATCH: Value (type $($desiredType.Name)) for property '$key' does match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValuesClean.$key)'"
            continue
        }
                    
        if ($DesiredValuesClean.GetType().Name -in 'HashTable', 'PSBoundParametersDictionary')
        {
            $checkDesiredValue = $DesiredValuesClean.ContainsKey($key)
        } 
        else
        {
            $checkDesiredValue = Test-DSCObjectHasProperty -Object $DesiredValuesClean -PropertyName $key
        }
        
        if (-not $checkDesiredValue)
        {
            Write-Verbose -Message "MATCH: Value (type $($desiredType.Name)) for property '$key' does match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValuesClean.$key)'"
            continue
        }
        
        if ($desiredType.IsArray)
        {
            Write-Verbose "Comparing values in property '$key'"
            if (-not $CurrentValues.ContainsKey($key) -or -not $CurrentValues.$key)
            {
                Write-Verbose -Message "NOTMATCH: Value (type $($desiredType.Name)) for property '$key' does not match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValuesClean.$key)'"
                $returnValue = $false
                continue
            }
            elseif ($CurrentValues.$key.Count -ne $DesiredValues.$key.Count)
            {
                Write-Verbose -Message "NOTMATCH: Value (type $($desiredType.Name)) for property '$key' does have a different count. Current state count is '$($CurrentValues.$key.Count)' and desired state count is '$($DesiredValuesClean.$key.Count)'"
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
                        $desiredType = [psobject]@{ Name = 'Unknown' }
                    }
                    
                    if ($null -ne $currentArrayValues[$i])
                    {
                        $currentType = $currentArrayValues[$i].GetType()
                    }
                    else
                    {
                        $currentType = [psobject]@{ Name = 'Unknown' }
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
        else {
            if ($DesiredValuesClean.$key -ne $CurrentValues.$key)
            {
                Write-Verbose -Message "NOTMATCH: Value (type $($desiredType.Name)) for property '$key' does not match. Current state is '$($CurrentValues.$key)' and desired state is '$($DesiredValuesClean.$key)'"
                $returnValue = $false
            }
        
        } 
    }
    
    Write-Verbose "Result is '$returnValue'"
    return $returnValue
}

function Test-DSCObjectHasProperty
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory)] 
        [object]
        $Object,

        [Parameter(Mandatory)]
        [string]
        $PropertyName
    )

    if ($Object.PSObject.Properties.Name -contains $PropertyName) 
    {
        return [bool]$Object.$PropertyName
    }
    
    return $false
}

Export-ModuleMember -Function @(
    'Get-LocalizedData'
    'Remove-CommonParameter'
    'Test-DscParameterState'
    'Test-DSCObjectHasProperty'
    )
