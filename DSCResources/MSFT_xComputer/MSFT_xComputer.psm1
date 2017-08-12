[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "", Scope = "Function")]
param
(
)

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 15)]
        [ValidateScript( {$_ -inotmatch '[\/\\:*?"<>|]' })]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $DomainName,

        [Parameter()]
        [System.String]
        $JoinOU,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $UnjoinCredential,

        [Parameter()]
        [System.String]
        $WorkGroupName
    )

    Write-Verbose -Message "Getting computer state for '$($Name)'."

    $convertToCimCredential = New-CimInstance `
        -ClassName MSFT_Credential `
        -Property @{
            Username = [System.String] $Credential.UserName
            Password = [System.String] $null
        } `
        -Namespace root/microsoft/windows/desiredstateconfiguration `
        -ClientOnly

    $convertToCimUnjoinCredential = New-CimInstance `
        -ClassName MSFT_Credential `
        -Property @{
            Username = [System.String] $UnjoinCredential.UserName
            Password = [System.String]$null
        } `
        -Namespace root/microsoft/windows/desiredstateconfiguration `
        -ClientOnly

    $returnValue = @{
        Name             = $env:COMPUTERNAME
        DomainName       = Get-ComputerDomain
        JoinOU           = $JoinOU
        CurrentOU        = Get-ComputerOU
        Credential       = [ciminstance]$convertToCimCredential
        UnjoinCredential = [ciminstance]$convertToCimUnjoinCredential
        WorkGroupName    = (Get-CimInstance -Class 'Win32_ComputerSystem').Workgroup
    }

    $returnValue
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 15)]
        [ValidateScript( {$_ -inotmatch '[\/\\:*?"<>|]' })]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $DomainName,

        [Parameter()]
        [System.String]
        $JoinOU,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $UnjoinCredential,

        [Parameter()]
        [System.String]
        $WorkGroupName
    )

    Assert-DomainOrWorkGroup -DomainName $DomainName -WorkGroupName $WorkGroupName

    if ($Name -eq 'localhost')
    {
        $Name = $env:COMPUTERNAME
    }

    if ($Credential)
    {
        if ($DomainName)
        {
            if ($DomainName -eq (Get-ComputerDomain))
            {
                # Rename the computer, but stay joined to the domain.
                Rename-Computer -NewName $Name -DomainCredential $Credential -Force
                Write-Verbose -Message "Renamed computer to '$($Name)'."
            }
            else
            {
                if ($Name -ne $env:COMPUTERNAME)
                {
                    # Rename the computer, and join it to the domain.
                    if ($UnjoinCredential)
                    {
                        Add-Computer -DomainName $DomainName -Credential $Credential -NewName $Name -UnjoinDomainCredential $UnjoinCredential -Force
                    }
                    else
                    {
                        if ($JoinOU)
                        {
                            Add-Computer -DomainName $DomainName -Credential $Credential -NewName $Name -OUPath $JoinOU -Force
                        }
                        else
                        {
                            Add-Computer -DomainName $DomainName -Credential $Credential -NewName $Name -Force
                        }
                    }
                    Write-Verbose -Message "Renamed computer to '$($Name)' and added to the domain '$($DomainName)."
                }
                else
                {
                    # Same computer name, and join it to the domain.
                    if ($UnjoinCredential)
                    {
                        Add-Computer -DomainName $DomainName -Credential $Credential -UnjoinDomainCredential $UnjoinCredential -Force
                    }
                    else
                    {
                        if ($JoinOU)
                        {
                            Add-Computer -DomainName $DomainName -Credential $Credential -OUPath $JoinOU -Force
                        }
                        else
                        {
                            Add-Computer -DomainName $DomainName -Credential $Credential -Force
                        }
                    }
                    Write-Verbose -Message "Added computer to domain '$($DomainName)."
                }
            }
        }
        elseif ($WorkGroupName)
        {
            if ($WorkGroupName -eq (Get-CimInstance -Class 'Win32_ComputerSystem').Workgroup)
            {
                # Rename the computer, but stay in the same workgroup.
                Rename-Computer -NewName $Name
                Write-Verbose -Message "Renamed computer to '$($Name)'."
            }
            else
            {
                if ($Name -ne $env:COMPUTERNAME)
                {
                    # Rename the computer, and join it to the workgroup.
                    Add-Computer -NewName $Name -Credential $Credential -WorkgroupName $WorkGroupName -Force
                    Write-Verbose -Message "Renamed computer to '$($Name)' and addded to workgroup '$($WorkGroupName)'."
                }
                else
                {
                    # Same computer name, and join it to the workgroup.
                    Add-Computer -WorkGroupName $WorkGroupName -Credential $Credential -Force
                    Write-Verbose -Message "Added computer to workgroup '$($WorkGroupName)'."
                }
            }
        }
        elseif ($Name -ne $env:COMPUTERNAME)
        {
            if (Get-ComputerDomain)
            {
                Rename-Computer -NewName $Name -DomainCredential $Credential -Force
                Write-Verbose -Message "Renamed computer to '$($Name)'."
            }
            else
            {
                Rename-Computer -NewName $Name -Force
                Write-Verbose -Message "Renamed computer to '$($Name)'."
            }
        }
    }
    else
    {
        if ($DomainName)
        {
            throw 'Missing domain join credentials.'
        }
        if ($WorkGroupName)
        {

            if ($WorkGroupName -eq (Get-CimInstance -Class 'Win32_ComputerSystem').Workgroup)
            {
                # Same workgroup, new computer name
                Rename-Computer -NewName $Name -force
                Write-Verbose -Message "Renamed computer to '$($Name)'."
            }
            else
            {
                if ($name -ne $env:COMPUTERNAME)
                {
                    # New workgroup, new computer name
                    Add-Computer -WorkgroupName $WorkGroupName -NewName $Name
                    Write-Verbose -Message "Renamed computer to '$($Name)' and added to workgroup '$($WorkGroupName)'."
                }
                else
                {
                    # New workgroup, same computer name
                    Add-Computer -WorkgroupName $WorkGroupName
                    Write-Verbose -Message "Added computer to workgroup '$($WorkGroupName)'."
                }
            }
        }
        else
        {
            if ($Name -ne $env:COMPUTERNAME)
            {
                Rename-Computer -NewName $Name
                Write-Verbose -Message "Renamed computer to '$($Name)'."
            }
        }
    }

    $global:DSCMachineStatus = 1
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 15)]
        [ValidateScript( {$_ -inotmatch '[\/\\:*?"<>|]' })]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $JoinOU,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $UnjoinCredential,

        [Parameter()]
        [System.String]
        $DomainName,

        [Parameter()]
        [System.String]
        $WorkGroupName
    )

    Write-Verbose -Message 'Validate desired Name is a valid name'

    Write-Verbose -Message 'Checking if computer name is correct'
    if (($Name -ne 'localhost') -and ($Name -ne $env:COMPUTERNAME))
    {
        return $false
    }

    Assert-DomainOrWorkGroup -DomainName $DomainName -WorkGroupName $WorkGroupName

    if ($DomainName)
    {
        if (-not ($Credential))
        {
            throw 'Need to specify credentials with domain'
        }

        try
        {
            Write-Verbose "Checking if the machine is a member of $DomainName."

            if ($DomainName.Contains('.'))
            {
                $getComputerDomainParameters = @{
                    netbios = $false
                }
            }
            else
            {
                $getComputerDomainParameters = @{
                    netbios = $true
                }
            }

            return ($DomainName -eq (Get-ComputerDomain @getComputerDomainParameters))
        }
        catch
        {
            Write-Verbose 'The machine is not a domain member.'

            return $false
        }
    }
    elseif ($WorkGroupName)
    {
        Write-Verbose -Message "Checking if workgroup name is $WorkGroupName"

        return ($WorkGroupName -eq (Get-CimInstance -Class 'Win32_ComputerSystem').Workgroup)
    }
    else
    {
        # No Domain or Workgroup specified and computer name is correct
        return $true
    }
}

function Assert-DomainOrWorkGroup($DomainName, $WorkGroupName)
{
    if ($DomainName -and $WorkGroupName)
    {
        throw 'Only DomainName or WorkGroupName can be specified at once.'
    }
}

function Get-ComputerDomain
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [Switch]
        $NetBios
    )

    try
    {
        if ($NetBios)
        {
            $domainName = $ENV:USERDOMAIN
        }
        else
        {
            $domainName = ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).Name
        }
        return $domainName
    }
    catch [System.Management.Automation.MethodInvocationException]
    {
        Write-Debug 'This machine is not a domain member.'
    }
}

function Get-ComputerOU
{
    $ou = $null

    if (Get-ComputerDomain)
    {
        $dn = $null
        $dn = ([adsisearcher]"(&(objectCategory=computer)(objectClass=computer)(cn=$env:COMPUTERNAME))").FindOne().Properties.distinguishedname
        $ou = $dn -replace '^(CN=.*?(?<=,))', ''
    }

    return $ou
}

Export-ModuleMember -Function *-TargetResource
