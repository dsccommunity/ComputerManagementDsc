[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "", Scope = "Function")]
param
(
)

$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import the ComputerManagementDsc Resource Helper Module
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.ResourceHelper' `
            -ChildPath 'ComputerManagementDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'MSFT_xVirtualMemory' `
    -ResourcePath (Split-Path -Parent $Script:MyInvocation.MyCommand.Path)

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

    Write-Verbose -Message ($script:localizedData.GettingVirtualMemoryMessage)

    $returnValue = @{
        Drive       = [string]::Empty
        Type        = [string]::Empty
        InitialSize = 0
        MaximumSize = 0
    }

    [System.Boolean] $isSystemManaged = (Get-CimInstance -ClassName 'Win32_ComputerSystem').AutomaticManagedPagefile

    if ($isSystemManaged)
    {
        $returnValue.Type = 'AutoManagePagingFile'
        return $returnValue
    }

    $driveInfo = [System.IO.DriveInfo] $Drive

    $existingPageFileSetting = Get-PageFileSetting `
        -Drive $($driveInfo.Name.Substring(0,2))

    if (-not $existingPageFileSetting)
    {
        $returnValue.Type = 'NoPagingFile'
    }
    else
    {
        if ($existingPageFileSetting.InitialSize -eq 0 -and $existingPageFileSetting.MaximumSize -eq 0)
        {
            $returnValue.Type = 'SystemManagedSize'
        }
        else
        {
            $returnValue.Type = 'CustomSize'
        }

        $returnValue.Drive = $existingPageFileSetting.Name.Substring(0, 3)
        $returnValue.InitialSize = $existingPageFileSetting.InitialSize
        $returnValue.MaximumSize = $existingPageFileSetting.MaximumSize
    }

    return $returnValue
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

    Write-Verbose -Message ($script:localizedData.SettingVirtualMemoryMessage)

    $systemInfo = Get-CimInstance -ClassName 'Win32_ComputerSystem'

    switch ($Type)
    {
        'AutoManagePagingFile'
        {
            Set-AutoManagePaging -State Enable

            $global:DSCMachineStatus = 1

            break
        }

        'CustomSize'
        {
            if ($systemInfo.AutomaticManagedPageFile)
            {
                # First Disable Automatic Managed Page File
                Set-AutoManagePaging -State Disable
            }

            $driveInfo = Get-DriveInfo -Drive $Drive

            $existingPageFileSetting = Get-PageFileSetting `
                -Drive $($driveInfo.Name.Substring(0,2))

            if (-not $existingPageFileSetting)
            {
                $pageFileName = Join-Path `
                    -Path $driveInfo.Name `
                    -ChildPath 'pagefile.sys'

                New-PageFile -PageFileName $pageFileName
            }

            Set-PageFileSetting `
                -Drive $driveInfo.Name.Substring(0,2) `
                -InitialSize $InitialSize `
                -MaximumSize $MaximumSize

            $global:DSCMachineStatus = 1

            Write-Verbose -Message ($script:localizedData.EnabledCustomSizeMessage -f $Drive)

            break
        }

        'SystemManagedSize'
        {
            if ($systemInfo.AutomaticManagedPageFile)
            {
                # First Disable Automatic Managed Page File
                Set-AutoManagePaging -State Disable
            }

            $driveInfo = Get-DriveInfo -Drive $Drive

            $existingPageFileSetting = Get-PageFileSetting `
                -Drive $($driveInfo.Name.Substring(0,2))

            if (-not $existingPageFileSetting)
            {
                $pageFileName = Join-Path `
                    -Path $driveInfo.Name `
                    -ChildPath 'pagefile.sys'

                New-PageFile -PageFileName $pageFileName
            }

            Set-PageFileSetting `
                -Drive $driveInfo.Name.Substring(0,2)

            $global:DSCMachineStatus = 1

            Write-Verbose -Message ($script:localizedData.EnabledSystemManagedSizeMessage -f $Drive)

            break
        }

        'NoPagingFile'
        {
            if ($systemInfo.AutomaticManagedPageFile)
            {
                # First Disable Automatic Managed Page File
                Set-AutoManagePaging -State Disable
            }

            $driveInfo = Get-DriveInfo -Drive $Drive

            $existingPageFileSetting = Get-PageFileSetting `
                -Drive $($driveInfo.Name.Substring(0,2))

            if ($existingPageFileSetting)
            {
                Write-Verbose -Message ($script:localizedData.RemovePageFileMessage -f $existingPageFileSetting.Name)

                $null = Remove-CimInstance `
                    -InputObject $existingPageFileSetting

                $global:DSCMachineStatus = 1
            }

            Write-Verbose -Message ($script:localizedData.DisabledPageFileMessage -f $Drive)

            break
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

    Write-Verbose -Message ($script:localizedData.TestingVirtualMemoryMessage)

    $systemInfo = Get-CimInstance -ClassName 'Win32_ComputerSystem'
    $inDesiredState = $false

    switch ($Type)
    {
        'AutoManagePagingFile'
        {
            $inDesiredState = $systemInfo.AutomaticManagedPagefile
            break
        }

        'CustomSize'
        {
            if ($systemInfo.AutomaticManagedPageFile)
            {
                break
            }

            $driveInfo = [System.IO.DriveInfo] $Drive

            $existingPageFileSetting = Get-PageFileSetting `
                -Drive $($driveInfo.Name.Substring(0,2))

            if (-not $existingPageFileSetting)
            {
                break
            }

            if (-not ($existingPageFileSetting.InitialSize -eq $InitialSize -and $existingPageFileSetting.MaximumSize -eq $MaximumSize))
            {
                break
            }

            $inDesiredState = $true
            break
        }

        'SystemManagedSize'
        {
            if ($systemInfo.AutomaticManagedPageFile)
            {
                break
            }

            $driveInfo = [System.IO.DriveInfo] $Drive

            $existingPageFileSetting = Get-PageFileSetting `
                -Drive $($driveInfo.Name.Substring(0,2))

            if (-not $existingPageFileSetting)
            {
                break
            }

            if (-not ($existingPageFileSetting.InitialSize -eq 0 -and $existingPageFileSetting.MaximumSize -eq 0))
            {
                break
            }

            $inDesiredState = $true
            break
        }

        'NoPagingFile'
        {
            if ($systemInfo.AutomaticManagedPageFile)
            {
                break
            }

            $driveInfo = [System.IO.DriveInfo] $Drive

            $existingPageFileSetting = Get-PageFileSetting `
                -Drive $($driveInfo.Name.Substring(0,2))

            if ($existingPageFileSetting)
            {
                break
            }

            $inDesiredState = $true
            break
        }
    }

    return $inDesiredState
}

<#
    .SYNOPSIS
        Gets the settings for a page file assigned to a Drive.

    .PARAMETER State
        The drive letter for the page file to return the settings of.
#>
function Get-PageFileSetting
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Drive
    )

    Write-Verbose -Message ($script:localizedData.GettingPageFileSettingsMessage -f $Drive)

    # Find existing page file settings by drive letter
    return Get-CimInstance `
        -ClassName 'Win32_PageFileSetting' `
        -Filter "SettingID='pagefile.sys @ $Drive'"
}

<#
    .SYNOPSIS
        Sets a new page file name.

    .PARAMETER Drive
        The letter of the drive containing the page file
        to change the settings of.

    .PARAMETER InitialSize
        The initial size to set the page file to.

    .PARAMETER MaximumSize
        The maximum size to set the page file to.
#>
function Set-PageFileSetting
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Drive,

        [Parameter()]
        [System.Int64]
        $InitialSize = 0,

        [Parameter()]
        [System.Int64]
        $MaximumSize = 0
    )

    $setParams = @{
        Namespace = 'root\cimv2'
        Query     = "Select * from Win32_PageFileSetting where SettingID='pagefile.sys @ $Drive'"
        Property  = @{
            InitialSize = $InitialSize
            MaximumSize = $MaximumSize
        }
    }

    Write-Verbose -Message ($script:localizedData.SettingPageFileSettingsMessage -f $Drive, $InitialSize, $MaximumSize)

    $null = Set-CimInstance @setParams
}

<#
    .SYNOPSIS
        Enables or Disables Automatically Managed Paging.

    .PARAMETER State
        Specifies if Automatically Managed Paging is enabled
        or disabled.
#>
function Set-AutoManagePaging
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Enable', 'Disable')]
        [System.String]
        $State
    )

    $setParams = @{
        Namespace = 'root\cimv2'
        Query     = 'Select * from Win32_ComputerSystem'
        Property  = @{
            AutomaticManagedPageFile = ($State -eq 'Enable')
        }
    }

    Write-Verbose -Message ($script:localizedData.SetAutoManagePagingMessage -f $State)

    $null = Set-CimInstance @setParams
}

<#
    .SYNOPSIS
        Sets a new page file name.

    .PARAMETER PageFileName
        The name of the new page file.
#>
function New-PageFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $PageFileName
    )

    Write-Verbose -Message ($script:localizedData.NewPageFileMessage -f $State)

    $null = New-CimInstance `
        -Namespace 'root\cimv2' `
        -ClassName 'Win32_PageFileSetting' `
        -Property @{
            Name = $PageFileName
        }
}

<#
    .SYNOPSIS
        Gets the Drive info object for a specified
        Drive. It will throw an exception if the drive
        is invalid or does not exist.

    .PARAMETER Drive
        The letter of the drive to get the drive info
        for.
#>
function Get-DriveInfo
{
    [CmdletBinding()]
    [OutputType([System.IO.DriveInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Drive
    )

    $driveInfo = [System.IO.DriveInfo] $Drive

    if (-not $driveInfo.IsReady)
    {
        New-InvalidOperationException `
            -Message ($script:localizedData.DriveNotReadyError -f $driveInfo.Name)
    }

    return $driveInfo
}

Export-ModuleMember -Function *-TargetResource
