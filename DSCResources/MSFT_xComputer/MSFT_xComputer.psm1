#
# xComputer: DSC resource to rename a computer and add it to a domain or
# workgroup.
#

# Forcing en-US for dev purposes
$LocalizedData = Import-LocalizedData -FileName "MSFT_xComputer.strings.psd1" -UICulture 'en-US'

function Get-TargetResource
{
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory)]
        [ValidateScript({ValidateName -Name $_})]
        [string] $Name,

        [string] $DomainName,

        [string] $JoinOU,

        [PSCredential] $Credential,

        [PSCredential] $UnjoinCredential,

        [string] $WorkGroupName
    )

    Write-Verbose -Message $LocalizedData.GetTargetResourceStartVerboseMessage

    $convertToCimCredential = New-CimInstance -ClassName MSFT_Credential -Property @{Username=[string]$Credential.UserName; Password=[string]$null} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly
    $convertToCimUnjoinCredential = New-CimInstance -ClassName MSFT_Credential -Property @{Username=[string]$UnjoinCredential.UserName; Password=[string]$null} -Namespace root/microsoft/windows/desiredstateconfiguration -ClientOnly

    $returnValue = @{
        Name = $env:COMPUTERNAME
        DomainName = GetComputerDomain
        JoinOU = $JoinOU
        CurrentOU = Get-ComputerOU
        Credential = [ciminstance]$convertToCimCredential
        UnjoinCredential = [ciminstance]$convertToCimUnjoinCredential
        WorkGroupName= (gwmi WIN32_ComputerSystem).WorkGroup
    }

    Write-Verbose -Message $LocalizedData.GetTargetResourceEndVerboseMessage
    $returnValue
}

function Set-TargetResource
{
    param
    (
        [parameter(Mandatory)]
        [ValidateLength(1,15)]
        [ValidateScript({ValidateName -Name $_})]
        [string] $Name,
    
        [string] $DomainName,

        [string] $JoinOU,
        
        [PSCredential] $Credential,

        [PSCredential] $UnjoinCredential,

        [string] $WorkGroupName
    )

    Write-Verbose -Message $LocalizedData.SetTargetResourceStartVerboseMessage

    ValidateDomainOrWorkGroup -DomainName $DomainName -WorkGroupName $WorkGroupName
    
    if ($Name -eq 'localhost')
    {
        $Name = $env:COMPUTERNAME
    }

    if ($Credential)
    {
        if ($DomainName)
        {
            if ($DomainName -eq (GetComputerDomain))
            {
                # Rename the computer, but stay joined to the domain.
                Rename-Computer -NewName $Name -DomainCredential $Credential -Force
                Write-Verbose -Message ($LocalizedData.SetNameRename -f $Name)
            }
            else
            {
                if ($Name -ne $env:COMPUTERNAME)
                {
                    # Rename the comptuer, and join it to the domain.
                    if ($UnjoinCredential)
                    {
                        Add-Computer -DomainName $DomainName -Credential $Credential -NewName $Name -UnjoinDomainCredential $UnjoinCredential -Force
                    }
                    else
                    {
                        if ($JoinOU) {
                            Add-Computer -DomainName $DomainName -Credential $Credential -NewName $Name -OUPath $JoinOU -Force
                        }
                        else {
                            Add-Computer -DomainName $DomainName -Credential $Credential -NewName $Name -Force
                        }
                    }
                    Write-Verbose -Message ($LocalizedData.SetNameRenameAndJoinDomain -f $Name, $DomainName)
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
                        if ($JoinOU) {
                            Add-Computer -DomainName $DomainName -Credential $Credential -OUPath $JoinOU -Force
                        }
                        else {
                            Add-Computer -DomainName $DomainName -Credential $Credential -Force
                        }
                    }
                    Write-Verbose -Message ($LocalizedData.SetDomainJoin -f $DomainName)
                }
            }
        }
        elseif ($WorkGroupName)
        {
            if($WorkGroupName -eq (gwmi win32_computersystem).WorkGroup)
            {
                # Rename the computer, but stay in the same workgroup.
                Rename-Computer -NewName $Name
                Write-Verbose -Message ($LocalizedData.SetNameRename -f $Name)
            }
            else
            {
                if ($Name -ne $env:COMPUTERNAME)
                {
                    # Rename the computer, and join it to the workgroup.
                    Add-Computer -NewName $Name -Credential $Credential -WorkgroupName $WorkGroupName -Force
                    Write-Verbose -Message ($LocalizedData.SetNameRenameAndJoinWorkGroup -f $Name, $WorkGroupName)
                }
                else
                {
                    # Same computer name, and join it to the workgroup.
                    Add-Computer -WorkGroupName $WorkGroupName -Credential $Credential -Force
                    Write-Verbose -Message ($LocalizedData.SetWorkGroupJoin -f $WorkGroupName)
                }
            }
        }
        elseif($Name -ne $env:COMPUTERNAME)
        {
            if (GetComputerDomain)
            {
                Rename-Computer -NewName $Name -DomainCredential $Credential -Force
                Write-Verbose -Message ($LocalizedData.SetNameRename -f $Name)
            }
            else
            {
                Rename-Computer -NewName $Name -Force
                Write-Verbose -Message ($LocalizedData.SetNameRename -f $Name)
            }
        }
    }
    else
    {
        if ($DomainName)
        {
            throw ($LocalizedData.SetDomainJoinNoCredential -f $DomainName)
        }
        if ($WorkGroupName)
        {
            
            if ($WorkGroupName -eq (Get-WmiObject win32_computersystem).Workgroup)
            {
                # Same workgroup, new computer name
                Rename-Computer -NewName $Name -force
                Write-Verbose -Message ($LocalizedData.SetNameRename -f $Name)
            }
            else
            {
                if ($name -ne $env:COMPUTERNAME)
                {
                    # New workgroup, new computer name
                    Add-Computer -WorkgroupName $WorkGroupName -NewName $Name
                    Write-Verbose -Message ($LocalizedData.SetNameRenameAndJoinWorkGroup -f $Name, $WorkGroupName)
                }
                else
                {
                    # New workgroup, same computer name
                    Add-Computer -WorkgroupName $WorkGroupName
                    Write-Verbose -Message ($LocalizedData.SetWorkGroupJoin -f $WorkGroupName)
                }
            }
        }
        else
        {
            if ($Name -ne $env:COMPUTERNAME)
            {
                Rename-Computer -NewName $Name
                Write-Verbose -Message ($LocalizedData.SetNameRename -f $Name)
            }
        }
    }

    $global:DSCMachineStatus = 1
}
function Test-TargetResource
{
    [OutputType([System.Boolean])]
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [ValidateScript({ValidateName -Name $_})]
        [string] $Name,

        [string] $JoinOU,
        
        [PSCredential]$Credential,

        [PSCredential]$UnjoinCredential,
        
        [string] $DomainName,

        [string] $WorkGroupName
    )
    
    Write-Verbose -Message $LocalizedData.TestNameStart
    
    Write-Verbose -Message $LocalizedData.TestNameStart
    if (($Name -ne 'localhost') -and ($Name -ne $env:COMPUTERNAME)) 
    {
        WriteTestFailure -ParameterName 'Name' -Expected $Name -Got $env:COMPUTERNAME
        return $false
    }
    Write-Verbose -Message $LocalizedData.Success

    ValidateDomainOrWorkGroup -DomainName $DomainName -WorkGroupName $WorkGroupName

    if($DomainName)
    {
        if(!($Credential))
        {
            throw ($LocalizedData.TestDomainCredentialsNotSpecifiedFailure -f $DomainName)
        }
        
        try
        {
            Write-Verbose ($LocalizedData.TestDomainAlreadyMemberStart -f $DomainName)
            $CurDomain = GetComputerDomain
            if($DomainName.ToLower() -ne $CurDomain.ToLower())
            {
                WriteTestFailure -ParameterName 'DomainName' -Expected $DomainName -Got $CurDomain
                return $false
            }
        }
        catch
        {
           Write-Verbose ($LocalizedData.TestDomainComputerNotMemberOfAny -f $DomainName)
           return $false
        }
    }
    elseif($WorkGroupName)
    {
        Write-Verbose -Message $LocalizedData.TestWorkGroupStart
        $CurWorkGroupName = (gwmi WIN32_ComputerSystem).WorkGroup
        if ($WorkGroupName -ne $CurWorkGroupName)
        {
            WriteTestFailure -ParameterName 'WorkGroupName' -Expected $WorkGroupName -Got $CurWorkGroupName
            return $false
        }
    }

    Write-Verbose -Message $LocalizedData.InDesiredState
    return $true
}

function ValidateDomainOrWorkGroup($DomainName, $WorkGroupName)
{
    if ($DomainName -and $WorkGroupName)
    {
        throw $LocalizedData.TestDomainOrWorkGroupFailure
    }
}

function GetComputerDomain
{
  try
    {
        return ([System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()).Name
    }
    catch [System.Management.Automation.MethodInvocationException]
    {
        Write-Debug $LocalizedData.TestDomainComputerNotMemberOfAny
    }
}

function Get-ComputerOU
{
    $ou = $null

    if (GetComputerDomain)
    {
        $dn = $null
        $dn = ([adsisearcher]"(&(objectCategory=computer)(objectClass=computer)(cn=$env:COMPUTERNAME))").FindOne().Properties.distinguishedname
        $ou = $dn -replace '^(CN=.*?(?<=,))', ''
    }

    return $ou
}

# Source: https://support.microsoft.com/en-gb/kb/909264
# Removed entries with spaces as a computername cannot have spaces
$ReservedNames = @(
    'Anonymous',
    'Batch',
    'BuiltIn',
    'DialUp',
    'Interactive',
    'Internet',
    'Local',
    'Network',
    'Null',
    'Proxy',
    'Restricted',
    'Self',
    'Server'
    'Service',
    'System'
    'Users'
    'World'
)

function ValidateName
{
    [OutputType([string])]
    param
    (
        [Parameter(Mandatory)]
        [string]$Name
    )

    Write-Verbose -Message ($LocalizedData.TestNameIsValidStart -f $Name)

    # Test if name has invalid characters. Character source: https://support.microsoft.com/en-gb/kb/909264
    if($Name -match '(\/|\\|\:|\*|\?|\"|\<|\>|\|)')
    {
        NameIsInvalidError -Name $Name -FailureReason $LocalizedData.TestNameIsValidFailureDisallowedCharacters
    }

    # Test if name starts with period.
    if($Name.Trim()[0] -eq '.')
    {
        NameIsInvalidError -Name $Name -FailureReason $LocalizedData.TestNameIsValidFailureStartsWithPeriod
    }

    # Test if name is whitespace only
    if([string]::IsNullOrWhiteSpace($Name))
    {
        NameIsInvalidError -Name $Name -FailureReason $LocalizedData.TestNameISValidFailureWhiteSpace
    }

    # Test if name is too short
    if($Name.Length -lt 1)
    {
        NameIsValidError -Name $Name -FailureReason $LocalizedData.TestNameIsValidFailureTooShort
    }

    # Test if name is too long
    if($Name.Length -gt 15)
    {
        NameIsInvalidError -Name $Name -FailureReason $LocalizedData.TestNameIsValidFailureTooLong
    }

    # Test if name is only numbers (Supports numbers at beginning)
    if(-not ($Name -match '[a-zA-Z]'))
    {
        NameIsInvalidError -Name $Name -FailureReason $LocalizedData.TestNameIsValidFailureOnlyNumbers
    }

    # Test if name is system reserved
    if($ReservedNames -contains $Name)
    {
        NameIsInvalidError -Name $Name -FailureReason $LocalizedData.TestNameIsValidFailureReservedName
    }

    # If it gets this far it's a success
    Write-Verbose -Message ($LocalizedData.TestNameIsValidSuccess -f $Name)
    return $true
}

function NameIsInvalidError
{
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$FailureReason
    )

    throw ($LocalizedData.TestNameIsValidFailureError -f $Name, $FailureReason)
}

function WriteTestFailure
{
    param(
        [Parameter(Mandatory)]
        [string]$ParameterName,

        [Parameter(Mandatory)]
        [string]$Expected,

        [Parameter(Mandatory)]
        [string]$Got,

        [switch]$Throw
    )

    $Output = ($LocalizedData.Failure -f $ParameterName, $Expected, $Got)
    if($Throw)
    {
        throw $Output
    }
    else
    {
        Write-Verbose -Message $Output
        Write-Verbose -Message $LocalizedData.NotInDesiredState
    }
    
}

Export-ModuleMember -Function *-TargetResource
