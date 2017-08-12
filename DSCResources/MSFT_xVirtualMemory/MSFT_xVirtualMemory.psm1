[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "", Scope = "Function")]
param
(
)

<#
    .SYNOPSIS
        Returns the current state of the virtual memory configuration

    .PARAMETER Drive
        The drive for which the virtual memory configuration needs to be returned

    .PARAMETER Type
        The type of the virtual memory configuration
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Drive,

        [Parameter(Mandatory = $true)]
        [ValidateSet('AutoManagePagingFile', 'CustomSize', 'SystemManagedSize', 'NoPagingFile')]
        [System.String]
        $Type
    )

    Write-Verbose -Message 'Getting current page file settings'

    $returnValue = @{
        Drive       = [string]::Empty
        Type        = [string]::Empty
        InitialSize = 0
        MaximumSize = 0
    }

    [bool] $isSystemManaged = (Get-CimInstance -ClassName Win32_ComputerSystem).AutomaticManagedPagefile

    if ($isSystemManaged)
    {
        $returnValue.Type = 'AutoManagePagingFile'
        return $returnValue
    }

    $driveItem = [System.IO.DriveInfo] $Drive

    Write-Verbose -Message "Pagefile was not automatically managed. Retrieving detailed page file settings with query Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveItem.Name.Substring(0,2))'"

    # Find existing page file settings by drive letter
    $virtualMemoryInstance = Get-CimInstance -Namespace root\cimv2 -Query "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveItem.Name.Substring(0,2))'"

    if (-not $virtualMemoryInstance)
    {
        $returnValue.Type = 'NoPagingFile'
        return $returnValue
    }

    if ($virtualMemoryInstance.InitialSize -eq 0 -and $virtualMemoryInstance.MaximumSize -eq 0)
    {
        $returnValue.Type = 'SystemManagedSize'
    }
    else
    {
        $returnValue.Type = 'CustomSize'
    }

    $returnValue.Drive = $virtualMemoryInstance.Name.Substring(0, 3)
    $returnValue.InitialSize = $virtualMemoryInstance.InitialSize
    $returnValue.MaximumSize = $virtualMemoryInstance.MaximumSize

    $returnValue
}

<#
    .SYNOPSIS
        Sets the virtual memory settings based on the parameters supplied

    .PARAMETER Drive
        The drive for which the virtual memory configuration should be set.

    .PARAMETER Type
        The paging type. When set to AutoManagePagingFile, drive letters are ignored

    .PARAMETER InitialSize
        The initial page file size in megabyte

    .PARAMETER MaximumSize
        The maximum page file size in megabyte. May not be smaller than InitialSize
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Drive,

        [Parameter(Mandatory = $true)]
        [ValidateSet('AutoManagePagingFile', 'CustomSize', 'SystemManagedSize', 'NoPagingFile')]
        [System.String]
        $Type,

        [Parameter()]
        [System.Int64]
        $InitialSize,

        [Parameter()]
        [System.Int64]
        $MaximumSize
    )

    Write-Verbose -Message 'Setting page file'

    $SystemInfo = Get-CimInstance -Class Win32_ComputerSystem

    switch ($Type)
    {
        'AutoManagePagingFile'
        {
            $setParams = @{
                Namespace = 'root\cimv2'
                Query     = 'Select * from Win32_ComputerSystem'
                Property  = @{AutomaticManagedPageFile = $true}
            }

            Write-Verbose -Message 'Enabling AutoManagePagingFile'

            $null = Set-CimInstance @setParams
            $global:DSCMachineStatus = 1
            break
        }

        'CustomSize'
        {
            if ($SystemInfo.AutomaticManagedPageFile)
            {
                # First set AutomaticManagedPageFile to $false to be able to set a custom one later

                $setParams = @{
                    Namespace = 'root\cimv2'
                    Query     = 'Select * from Win32_ComputerSystem'
                    Property  = @{AutomaticManagedPageFile = $false}
                }

                Write-Verbose -Message 'Disabling AutoManagePagingFile'

                $null = Set-CimInstance @setParams
            }

            $driveInfo = [System.IO.DriveInfo] $Drive

            if (-not $driveInfo.IsReady)
            {
                throw "Drive $($driveInfo.Name) is not ready. Please ensure that the drive exists and is available"
            }

            $pageFileName = Join-Path -Path $driveInfo.Name -ChildPath 'pagefile.sys'

            Write-Verbose -Message ('Checking if a paging file already exists at {0}' -f $pageFileName)
            $existingPageFileSetting = Get-CimInstance `
                -Namespace root\cimv2 `
                -Query "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"

            if (-not $existingPageFileSetting)
            {
                $null = New-CimInstance -Namespace 'root\cimv2' -ClassName 'Win32_PageFileSetting' -Property @{Name = $pageFileName}
            }

            <#
                New-CimInstance does not support properties InitialSize and MaximumSize. Therefore, create
                a New-CimInstance with the page file name only if it does not exist and Set-CimInstance on the instance
            #>
            $setParams = @{
                Namespace = 'root\cimv2'
                Query     = "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
                Property  = @{
                    InitialSize = $InitialSize
                    MaximumSize = $MaximumSize
                }
            }

            Write-Verbose -Message ("Setting page file to {0}. Initial size {1}MB, maximum size {2}MB" -f $pageFileName, $InitialSize, $MaximumSize)

            $null = Set-CimInstance @setParams
            $global:DSCMachineStatus = 1
            break
        }

        'SystemManagedSize'
        {
            if ($SystemInfo.AutomaticManagedPageFile)
            {
                $setParams = @{
                    Namespace = 'root\cimv2'
                    Query     = 'Select * from Win32_ComputerSystem'
                    Property  = @{AutomaticManagedPageFile = $false}
                }

                Write-Verbose -Message 'Disabling AutoManagePagingFile'

                $null = Set-CimInstance @setParams
            }

            $driveInfo = [System.IO.DriveInfo] $Drive

            if (-not $driveInfo.IsReady)
            {
                throw "Drive $($driveInfo.Name) is not ready. Please ensure that the drive exists and is available"
            }

            $pageFileName = Join-Path -Path $driveInfo.Name -ChildPath 'pagefile.sys'

            Write-Verbose -Message ('Checking if a paging file already exists at {0}' -f $pageFileName)

            $existingPageFileSetting = Get-CimInstance `
                -Namespace root\cimv2 `
                -Query "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"

            if (-not $existingPageFileSetting)
            {
                $null = New-CimInstance -Namespace 'root\cimv2' -ClassName 'Win32_PageFileSetting' -Property @{Name = $pageFileName}
            }

            $setParams = @{
                Namespace = 'root\cimv2'
                Query     = "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"
                Property  = @{
                    InitialSize = 0
                    MaximumSize = 0
                }
            }

            Write-Verbose -Message "Enabling system-managed page file on $pageFileName"

            $null = Set-CimInstance @setParams
            $global:DSCMachineStatus = 1
            break
        }

        'NoPagingFile'
        {
            if ($SystemInfo.AutomaticManagedPageFile)
            {
                $setParams = @{
                    Namespace = 'root\cimv2'
                    Query     = 'Select * from Win32_ComputerSystem'
                    Property  = @{AutomaticManagedPageFile = $false}
                }

                $null = Set-CimInstance @setParams
            }

            $driveInfo = [System.IO.DriveInfo] $Drive

            if (-not $driveInfo.IsReady)
            {
                throw "Drive $($driveInfo.Name) is not ready. Please ensure that the drive exists and is available"
            }

            $existingPageFileSetting = Get-CimInstance `
                -Namespace root\cimv2 `
                -Query "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"

            if ($existingPageFileSetting)
            {
                Write-Verbose -Message "Removing existing page file $($existingPageFileSetting.Name)"
                $null = Remove-CimInstance -InputObject $existingPageFileSetting
                $global:DSCMachineStatus = 1
            }

            Write-Verbose -Message "Disabled page file for drive $Drive"

            break
        }

        default
        {
            throw "A wrong type '$Type' has been selected."
        }
    }
}

<#
    .SYNOPSIS
        Tests if virtual memory settings need to be applied based on the parameters supplied

    .PARAMETER Drive
        The drive letter that should be tested

    .PARAMETER Type
        The type of the virtual memory configuration

    .PARAMETER InitialSize
        The initial page file size in megabyte

    .PARAMETER MaximumSize
        The maximum page file size in megabyte
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Drive,

        [Parameter(Mandatory = $true)]
        [ValidateSet('AutoManagePagingFile', 'CustomSize', 'SystemManagedSize', 'NoPagingFile')]
        [System.String]
        $Type,

        [Parameter()]
        [System.Int64]
        $InitialSize,

        [Parameter()]
        [System.Int64]
        $MaximumSize
    )

    Write-Verbose -Message 'Testing page file'

    $systemInfo = Get-CimInstance -Class Win32_ComputerSystem
    $result = $false

    switch ($Type)
    {
        'AutoManagePagingFile'
        {
            $result = $systemInfo.AutomaticManagedPagefile
            break
        }

        'CustomSize'
        {
            if ($systemInfo.AutomaticManagedPageFile)
            {
                $result = $false
                break
            }

            $driveInfo = [System.IO.DriveInfo] $Drive

            $pageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"

            if (-not $pageFile)
            {
                $result = $false
                break
            }

            if (-not ($pageFile.InitialSize -eq $InitialSize -and $pageFile.MaximumSize -eq $MaximumSize))
            {
                $result = $false
                break
            }

            $result = $true
            break
        }

        'SystemManagedSize'
        {
            if ($SystemInfo.AutomaticManagedPageFile)
            {
                $result = $false
                break
            }

            $driveInfo = [System.IO.DriveInfo] $Drive

            $pageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"

            if (-not $pageFile)
            {
                $result = $false
                break
            }

            if (-not ($pageFile.InitialSize -eq 0 -and $pageFile.MaximumSize -eq 0))
            {
                $result = $false
                break
            }

            $result = $true
            break
        }

        'NoPagingFile'
        {
            if ($SystemInfo.AutomaticManagedPageFile)
            {
                $result = $false
                break
            }

            $driveInfo = [System.IO.DriveInfo] $Drive

            $pageFile = Get-CimInstance -Class Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($driveInfo.Name.Substring(0,2))'"

            if ($pageFile)
            {
                $result = $false
                break
            }

            $result = $true
            break
        }

        default
        {
            break
        }
    }

    return $result
}

Export-ModuleMember -Function *-TargetResource
