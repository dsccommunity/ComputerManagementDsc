[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope = 'Function')]
param
(
)

$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'DSC_Computer'

$FailToRenameAfterJoinDomainErrorId = 'FailToRenameAfterJoinDomain,Microsoft.PowerShell.Commands.AddComputerCommand'

<#
    .SYNOPSIS
        Gets the current state of the computer.

    .PARAMETER Name
        The desired computer name.

    .PARAMETER DomainName
        The name of the domain to join.

    .PARAMETER JoinOU
        The distinguished name of the organizational unit that the computer
        account will be created in.

    .PARAMETER Credential
        Credential to be used to join a domain.

    .PARAMETER UnjoinCredential
        Credential to be used to leave a domain.

    .PARAMETER WorkGroupName
        The name of the workgroup.

    .PARAMETER Description
        The value assigned here will be set as the local computer description.

    .PARAMETER Server
        The Active Directory Domain Controller to use to join the domain.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 15)]
        [ValidateScript( { $_ -inotmatch '[\/\\:*?"<>|]' })]
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
        $WorkGroupName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.GettingComputerStateMessage -f $Name)

    $convertToCimCredential = New-CimInstance `
        -ClassName DSC_Credential `
        -Property @{
            Username = [System.String] $Credential.UserName
            Password = [System.String] $null
        } `
        -Namespace root/microsoft/windows/desiredstateconfiguration `
        -ClientOnly

    $convertToCimUnjoinCredential = New-CimInstance `
        -ClassName DSC_Credential `
        -Property @{
            Username = [System.String] $UnjoinCredential.UserName
            Password = [System.String] $null
        } `
        -Namespace root/microsoft/windows/desiredstateconfiguration `
        -ClientOnly

    $returnValue = @{
        Name             = $env:COMPUTERNAME
        DomainName       = Get-ComputerDomain
        JoinOU           = $JoinOU
        CurrentOU        = Get-ComputerOU
        Credential       = [ciminstance] $convertToCimCredential
        UnjoinCredential = [ciminstance] $convertToCimUnjoinCredential
        WorkGroupName    = (Get-CimInstance -Class 'Win32_ComputerSystem').Workgroup
        Description      = (Get-CimInstance -Class 'Win32_OperatingSystem').Description
        Server           = Get-LogonServer
    }

    return $returnValue
}

<#
    .SYNOPSIS
        Sets the current state of the computer.

    .PARAMETER Name
        The desired computer name.

    .PARAMETER DomainName
        The name of the domain to join.

    .PARAMETER JoinOU
        The distinguished name of the organizational unit that the computer
        account will be created in.

    .PARAMETER Credential
        Credential to be used to join a domain.

    .PARAMETER UnjoinCredential
        Credential to be used to leave a domain.

    .PARAMETER WorkGroupName
        The name of the workgroup.

    .PARAMETER Description
        The value assigned here will be set as the local computer description.

    .PARAMETER Server
        The Active Directory Domain Controller to use to join the domain.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 15)]
        [ValidateScript( { $_ -inotmatch '[\/\\:*?"<>|]' })]
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
        $WorkGroupName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.SettingComputerStateMessage -f $Name)

    Assert-DomainOrWorkGroup -DomainName $DomainName -WorkGroupName $WorkGroupName

    if ($Name -eq 'localhost')
    {
        $Name = $env:COMPUTERNAME
    }

    if ($PSBoundParameters.ContainsKey('Description'))
    {
        Write-Verbose -Message ($script:localizedData.SettingComputerDescriptionMessage -f $Description)
        $win32OperatingSystemCimInstance = Get-CimInstance -ClassName Win32_OperatingSystem
        $win32OperatingSystemCimInstance.Description = $Description
        Set-CimInstance -InputObject $win32OperatingSystemCimInstance
    }

    if ($Credential)
    {
        if ($DomainName)
        {
            if ($DomainName -eq (Get-ComputerDomain))
            {
                # Rename the computer, but stay joined to the domain.
                Rename-Computer -NewName $Name -DomainCredential $Credential -Force
                Write-Verbose -Message ($script:localizedData.RenamedComputerMessage -f $Name)
            }
            else
            {
                $addComputerParameters = @{
                    DomainName = $DomainName
                    Credential = $Credential
                    Force      = $true
                }
                $rename = $false
                if ($Name -ne $env:COMPUTERNAME)
                {
                    $addComputerParameters.Add("NewName", $Name)
                    $rename = $true
                }

                if ($UnjoinCredential)
                {
                    $addComputerParameters.Add("UnjoinDomainCredential", $UnjoinCredential)
                }

                if ($JoinOU)
                {
                    $addComputerParameters.Add("OUPath", $JoinOU)
                }

                if ($Server)
                {
                    $addComputerParameters.Add("Server", $Server)
                }

                # Rename the computer, and join it to the domain.
                try
                {
                    Add-Computer @addComputerParameters
                }
                catch [System.InvalidOperationException]
                {
                    <#
                        If the rename failed during the domain join, re-try the rename.
                        References to this issue:
                        https://social.technet.microsoft.com/Forums/windowsserver/en-US/81105b18-b1ff-4fcc-ae5c-2c1a7cf7bf3d/addcomputer-to-domain-with-new-name-returns-error
                        https://powershell.org/forums/topic/the-directory-service-is-busy/
                    #>
                    if ($_.FullyQualifiedErrorId -eq $failToRenameAfterJoinDomainErrorId)
                    {
                        Write-Verbose -Message $script:localizedData.FailToRenameAfterJoinDomainMessage
                        Rename-Computer -NewName $Name -DomainCredential $Credential
                    }
                    else
                    {
                        New-InvalidOperationException -ErrorRecord $_
                    }
                }
                catch
                {
                    throw $_
                }

                if ($rename)
                {
                    Write-Verbose -Message ($script:localizedData.RenamedComputerAndJoinedDomainMessage -f $Name, $DomainName)
                }
                else
                {
                    Write-Verbose -Message ($script:localizedData.JoinedDomainMessage -f $DomainName)
                }
            }
        }
        elseif ($WorkGroupName)
        {
            if ($WorkGroupName -eq (Get-CimInstance -Class 'Win32_ComputerSystem').Workgroup)
            {
                # Rename the computer, but stay in the same workgroup.
                Rename-Computer `
                    -NewName $Name

                Write-Verbose -Message ($script:localizedData.RenamedComputerMessage -f $Name)
            }
            else
            {
                if ($Name -ne $env:COMPUTERNAME)
                {
                    # Rename the computer, and join it to the workgroup.
                    Add-Computer `
                        -NewName $Name `
                        -Credential $Credential `
                        -WorkgroupName $WorkGroupName `
                        -Force

                    Write-Verbose -Message ($script:localizedData.RenamedComputerAndJoinedWorkgroupMessage -f $Name, $WorkGroupName)
                }
                else
                {
                    # Same computer name, and join it to the workgroup.
                    Add-Computer `
                        -WorkGroupName $WorkGroupName `
                        -Credential $Credential `
                        -Force

                    Write-Verbose -Message ($script:localizedData.JoinedWorkgroupMessage -f $WorkGroupName)
                }
            }
        }
        elseif ($Name -ne $env:COMPUTERNAME)
        {
            if (Get-ComputerDomain)
            {
                Rename-Computer `
                    -NewName $Name `
                    -DomainCredential $Credential `
                    -Force

                Write-Verbose -Message ($script:localizedData.RenamedComputerMessage -f $Name)
            }
            else
            {
                Rename-Computer `
                    -NewName $Name `
                    -Force

                Write-Verbose -Message ($script:localizedData.RenamedComputerMessage -f $Name)
            }
        }
    }
    else
    {
        if ($DomainName)
        {
            New-InvalidArgumentException `
                -Message ($script:localizedData.CredentialsNotSpecifiedError) `
                -ArgumentName 'Credentials'
        }

        if ($WorkGroupName)
        {
            if ($WorkGroupName -eq (Get-CimInstance -Class 'Win32_ComputerSystem').Workgroup)
            {
                # Same workgroup, new computer name
                Rename-Computer `
                    -NewName $Name `
                    -Force

                Write-Verbose -Message ($script:localizedData.RenamedComputerMessage -f $Name)
            }
            else
            {
                if ($name -ne $env:COMPUTERNAME)
                {
                    # New workgroup, new computer name
                    Add-Computer `
                        -WorkgroupName $WorkGroupName `
                        -NewName $Name

                    Write-Verbose -Message ($script:localizedData.RenamedComputerAndJoinedWorkgroupMessage -f $Name, $WorkGroupName)
                }
                else
                {
                    # New workgroup, same computer name
                    Add-Computer `
                        -WorkgroupName $WorkGroupName

                    Write-Verbose -Message ($script:localizedData.JoinedWorkgroupMessage -f $WorkGroupName)
                }
            }
        }
        else
        {
            if ($Name -ne $env:COMPUTERNAME)
            {
                Rename-Computer `
                    -NewName $Name

                Write-Verbose -Message ($script:localizedData.RenamedComputerMessage -f $Name)
            }
        }
    }

    $global:DSCMachineStatus = 1
}

<#
    .SYNOPSIS
        Tests the current state of the computer.

    .PARAMETER Name
        The desired computer name.

    .PARAMETER DomainName
        The name of the domain to join.

    .PARAMETER JoinOU
        The distinguished name of the organizational unit that the computer
        account will be created in.

    .PARAMETER Credential
        Credential to be used to join a domain.

    .PARAMETER UnjoinCredential
        Credential to be used to leave a domain.

    .PARAMETER WorkGroupName
        The name of the workgroup.

    .PARAMETER Description
        The value assigned here will be set as the local computer description.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateLength(1, 15)]
        [ValidateScript( { $_ -inotmatch '[\/\\:*?"<>|]' })]
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
        $WorkGroupName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $Server
    )

    Write-Verbose -Message ($script:localizedData.TestingComputerStateMessage -f $Name)

    if (($Name -ne 'localhost') -and ($Name -ne $env:COMPUTERNAME))
    {
        return $false
    }

    if ($PSBoundParameters.ContainsKey('Description'))
    {
        Write-Verbose -Message ($script:localizedData.CheckingComputerDescriptionMessage -f $Description)

        if ($Description -ne (Get-CimInstance -Class 'Win32_OperatingSystem').Description)
        {
            return $false
        }
    }

    Assert-DomainOrWorkGroup -DomainName $DomainName -WorkGroupName $WorkGroupName

    if ($DomainName)
    {
        if (-not ($Credential))
        {
            New-InvalidArgumentException `
                -Message ($script:localizedData.CredentialsNotSpecifiedError) `
                -ArgumentName 'Credentials'
        }

        try
        {
            Write-Verbose -Message ($script:localizedData.CheckingDomainMemberMessage -f $DomainName)

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
            Write-Verbose -Message ($script:localizedData.CheckingNotDomainMemberMessage)

            return $false
        }
    }
    elseif ($WorkGroupName)
    {
        Write-Verbose -Message ($script:localizedData.CheckingWorkgroupMemberMessage -f $WorkGroupName)

        return ($WorkGroupName -eq (Get-CimInstance -Class 'Win32_ComputerSystem').Workgroup)
    }
    else
    {
        # No Domain or Workgroup specified and computer name is correct
        return $true
    }
}

<#
    .SYNOPSIS
        Throws an exception if both the domain name and workgroup
        name is set.

    .PARAMETER DomainName
        The name of the domain to join.

    .PARAMETER WorkGroupName
        The name of the workgroup.
#>
function Assert-DomainOrWorkGroup
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $DomainName,

        [Parameter()]
        [System.String]
        $WorkGroupName
    )

    if ($DomainName -and $WorkGroupName)
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.DomainNameAndWorkgroupNameError)
    }
}

<#
    .SYNOPSIS
        Returns the domain the computer is joined to.

    .PARAMETER NetBios
        Specifies if the NetBIOS name is returned instead of
        the fully qualified domain name.
#>
function Get-ComputerDomain
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [Switch]
        $NetBios
    )

    try
    {
        $domainInfo = Get-CimInstance -ClassName Win32_ComputerSystem
        if ($domainInfo.PartOfDomain -eq $true)
        {
            if ($NetBios)
            {
                $domainName = (Get-Item -Path Env:\USERDOMAIN).Value
            }
            else
            {
                $domainName = $domainInfo.Domain
            }
        }
        else
        {
            $domainName = ''
        }

        return $domainName
    }
    catch [System.Management.Automation.MethodInvocationException]
    {
        Write-Verbose -Message ($script:localizedData.ComputerNotInDomainMessage)
    }
}

<#
    .SYNOPSIS
        Gets the organisation unit in the domain that the
        computer account exists in.
#>
function Get-ComputerOU
{
    [CmdletBinding()]
    param
    (
    )

    $ou = $null

    if (Get-ComputerDomain)
    {
        $dn = $null
        $dn = ([adsisearcher]"(&(objectCategory=computer)(objectClass=computer)(cn=$env:COMPUTERNAME))").FindOne().Properties.distinguishedname
        $ou = $dn -replace '^(CN=.*?(?<=,))', ''
    }

    return $ou
}

<#
    .SYNOPSIS
        Returns the logon server.
#>
function Get-LogonServer
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    $logonserver = $env:LOGONSERVER -replace "\\", ""
    return $logonserver
}

Export-ModuleMember -Function *-TargetResource
