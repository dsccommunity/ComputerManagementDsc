function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $HostName,
        
        [Parameter(Mandatory = $false)]
        [System.String]
        $IPAddress,
        
        [Parameter(Mandatory = $false)]
        [System.String]
        [ValidateSet("Present","Absent")]
        $Ensure = "Present"
    )
    $hosts = Get-Content "$env:windir\System32\drivers\etc\hosts"
    $allHosts = $hosts `
           | Where-Object { [System.String]::IsNullOrEmpty($_) -eq $false -and $_.StartsWith('#') -eq $false } `
           | ForEach-Object { 
                $data = $_ -split '\s+'
                return @{
                    Host = $data[1]
                    IP = $data[0]
                }
        } | Select-Object @{Name="Host";Expression={$_.Host}}, @{Name="IP";Expression={$_.IP}}
        
    $hostEntry = $allHosts | Where-Object { $_.Host -eq $HostName }
    
    if ($hostEntry -eq $null) 
    {
        return @{
            HostName = $HostName
            IPAddress = $null
            Ensure = "Absent"
        }
    }
    else 
    {
        return @{
            HostName = $hostEntry.Host
            IPAddress = $hostEntry.IP
            Ensure = "Present"
        }
    }
}

function Set-TargetResource
{
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $HostName,
        
        [Parameter(Mandatory = $false)]
        [System.String]
        $IPAddress,
        
        [Parameter(Mandatory = $false)]
        [System.String]
        [ValidateSet("Present","Absent")]
        $Ensure = "Present"
    )
    
    $currentValues = Get-TargetResource @PSBoundParameters
    
    if ($Ensure -eq "Present" -and $PSBoundParameters.ContainsKey("IPAddress") -eq $false) 
    {
        throw "Unable to ensure a host entry is present without a corresponding IP address. " + `
              "Please add the 'IPAddress' property and run this resource again."
        return
    }
    
    if ($currentValues.Ensure -eq "Absent" -and $Ensure -eq "Present")
    {
        Write-Verbose -Message "Creating new host entry for '$HostName'"
        Add-Content "$env:windir\System32\drivers\etc\hosts" "`r`n$IPAddress`t$HostName"
    }
    else 
    {
        $hosts = Get-Content "$env:windir\System32\drivers\etc\hosts"
        $replace = $hosts | Where-Object { $_ -like "*$HostName" }
        if ($currentValues.Ensure -eq "Present" -and $Ensure -eq "Present")
        {
            Write-Verbose -Message "Updating existing host entry for '$HostName'"
            $hosts = $hosts -replace $replace, "$IPAddress`t$HostName"
        }
        if ($Ensure -eq "Absent")
        {
            Write-Verbose -Message "Removing host entry for '$HostName'"
            $hosts = $hosts -replace $replace, ""
        }
        $hosts | Set-Content "$env:windir\System32\drivers\etc\hosts"
    }
}

function Test-TargetResource
{
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory = $true)]
        [System.String]
        $HostName,
        
        [Parameter(Mandatory = $false)]
        [System.String]
        $IPAddress,
        
        [Parameter(Mandatory = $false)]
        [System.String]
        [ValidateSet("Present","Absent")]
        $Ensure = "Present"
    )
    
    $currentValues = Get-TargetResource @PSBoundParameters
    
    if ($Ensure -ne $currentValues.Ensure) 
    {
        return $false
    }
   
    if ($Ensure -eq "Present" -and $IPAddress -ne $currentValues.IPAddress) 
    {
        return $false
    }
    return $true
}

