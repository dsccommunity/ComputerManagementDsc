[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "", Scope = "Function")]
param ()

$modulePath = Join-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -ChildPath 'Modules'

# Import the ComputerManagementDsc Common Modules
Import-Module -Name (Join-Path -Path $modulePath `
        -ChildPath (Join-Path -Path 'ComputerManagementDsc.Common' `
            -ChildPath 'ComputerManagementDsc.Common.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData -ResourceName 'DSC_PendingReboot'

<#
    This data file contains a list of reboot triggers that will be checked
    when determining if reboot is required. This is stored in a separate
    data file so that it can also be used in testing.
#>
$script:localizedResourceData = Get-LocalizedData `
    -ResourceName 'DSC_PendingReboot' `
    -Postfix 'data'
$script:rebootTriggers = $script:localizedResourceData.RebootTriggers
<#
    .SYNOPSIS
        Returns the current state of the pending reboot.

    .PARAMETER Name
        Specifies the name of this pending reboot check.
#>
function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Write-Verbose -Message ($script:localizedData.GettingPendingRebootStateMessage -f $Name)

    return Get-PendingRebootState @PSBoundParameters
}

<#
    .SYNOPSIS
        Sets the current state of the pending reboot.

    .PARAMETER Name
        Specifies the name of this pending reboot check.

    .PARAMETER SkipComponentBasedServicing
        Specifies whether to skip reboots triggered by the Component-Based Servicing component.

    .PARAMETER SkipWindowsUpdate
        Specifies whether to skip reboots triggered by Windows Update.

    .PARAMETER SkipPendingFileRename
        Specifies whether to skip pending file rename reboots.

    .PARAMETER SkipPendingComputerRename
        Specifies whether to skip reboots triggered by a pending computer rename.

    .PARAMETER SkipCcmClientSDK
        Specifies whether to skip reboots triggered by the ConfigMgr client. Defaults to True.
#>
function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Boolean]
        $SkipComponentBasedServicing,

        [Parameter()]
        [System.Boolean]
        $SkipWindowsUpdate,

        [Parameter()]
        [System.Boolean]
        $SkipPendingFileRename,

        [Parameter()]
        [System.Boolean]
        $SkipPendingComputerRename,

        [Parameter()]
        [System.Boolean]
        $SkipCcmClientSDK = $true
    )

    Write-Verbose -Message ($script:localizedData.SettingPendingRebootStateMessage -f $Name)

    $currentStatus = Get-PendingRebootState @PSBoundParameters

    if ($currentStatus.RebootRequired)
    {
        $global:DSCMachineStatus = 1
    }
}

<#
    .SYNOPSIS
        Tests the current state of the pending reboot.

    .PARAMETER Name
        Specifies the name of this pending reboot check.

    .PARAMETER SkipComponentBasedServicing
        Specifies whether to skip reboots triggered by the Component-Based Servicing component.

    .PARAMETER SkipWindowsUpdate
        Specifies whether to skip reboots triggered by Windows Update.

    .PARAMETER SkipPendingFileRename
        Specifies whether to skip pending file rename reboots.

    .PARAMETER SkipPendingComputerRename
        Specifies whether to skip reboots triggered by a pending computer rename.

    .PARAMETER SkipCcmClientSDK
        Specifies whether to skip reboots triggered by the ConfigMgr client. Defaults to True.
#>
function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Boolean]
        $SkipComponentBasedServicing,

        [Parameter()]
        [System.Boolean]
        $SkipWindowsUpdate,

        [Parameter()]
        [System.Boolean]
        $SkipPendingFileRename,

        [Parameter()]
        [System.Boolean]
        $SkipPendingComputerRename,

        [Parameter()]
        [System.Boolean]
        $SkipCcmClientSDK = $true
    )

    Write-Verbose -Message ($script:localizedData.TestingPendingRebootStateMessage -f $Name)

    $currentStatus = Get-PendingRebootState @PSBoundParameters

    return (-not $currentStatus.RebootRequired)
}

<#
    .SYNOPSIS
        Returns a hash table containing the current state of the pending reboot
        triggers.

    .PARAMETER Name
        Specifies the name of this pending reboot check.

    .PARAMETER SkipComponentBasedServicing
        Specifies whether to skip reboots triggered by the Component-Based Servicing component.

    .PARAMETER SkipWindowsUpdate
        Specifies whether to skip reboots triggered by Windows Update.

    .PARAMETER SkipPendingFileRename
        Specifies whether to skip pending file rename reboots.

    .PARAMETER SkipPendingComputerRename
        Specifies whether to skip reboots triggered by a pending computer rename.

    .PARAMETER SkipCcmClientSDK
        Specifies whether to skip reboots triggered by the ConfigMgr client. Defaults to True.
#>
function Get-PendingRebootHashTable
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Boolean]
        $SkipComponentBasedServicing,

        [Parameter()]
        [System.Boolean]
        $SkipWindowsUpdate,

        [Parameter()]
        [System.Boolean]
        $SkipPendingFileRename,

        [Parameter()]
        [System.Boolean]
        $SkipPendingComputerRename,

        [Parameter()]
        [System.Boolean]
        $SkipCcmClientSDK = $true
    )

    # The list of registry keys that will be used to determine if a reboot is required
    $rebootRegistryKeys = @{
        ComponentBasedServicing = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\'
        WindowsUpdate           = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\'
        PendingFileRename       = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\'
        ActiveComputerName      = 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName'
        PendingComputerName     = 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName'
    }

    $componentBasedServicingKeys = (Get-ChildItem -Path $rebootRegistryKeys.ComponentBasedServicing).Name

    if ($componentBasedServicingKeys)
    {
        $componentBasedServicing = $componentBasedServicingKeys.Split('\') -contains 'RebootPending'
    }
    else
    {
        $componentBasedServicing = $false
    }

    $windowsUpdateKeys = (Get-ChildItem -Path $rebootRegistryKeys.WindowsUpdate).Name

    if ($windowsUpdateKeys)
    {
        $windowsUpdate = $windowsUpdateKeys.Split('\') -contains 'RebootRequired'
    }
    else
    {
        $windowsUpdate = $false
    }

    $pendingFileRename = (Get-ItemProperty -Path $rebootRegistryKeys.PendingFileRename).PendingFileRenameOperations.Length -gt 0
    $activeComputerName = (Get-ItemProperty -Path $rebootRegistryKeys.ActiveComputerName).ComputerName
    $pendingComputerName = (Get-ItemProperty -Path $rebootRegistryKeys.PendingComputerName).ComputerName
    $pendingComputerRename = $activeComputerName -ne $pendingComputerName

    if ($SkipCcmClientSDK)
    {
        $ccmClientSDK = $false
    }
    else
    {
        $invokeCimMethodParameters = @{
            NameSpace   = 'ROOT\ccm\ClientSDK'
            ClassName   = 'CCM_ClientUtilities'
            Name        = 'DetermineIfRebootPending'
            ErrorAction = 'Stop'
        }

        try
        {
            $ccmClientSDK = Invoke-CimMethod @invokeCimMethodParameters
        }
        catch
        {
            Write-Warning -Message ($script:localizedData.QueryCcmClientUtilitiesFailedMessage -f $_)
        }

        $ccmClientSDK = ($ccmClientSDK.ReturnValue -eq 0) -and ($ccmClientSDK.IsHardRebootPending -or $ccmClientSDK.RebootPending)
    }

    return @{
        Name                        = $Name
        SkipComponentBasedServicing = $SkipComponentBasedServicing
        ComponentBasedServicing     = $componentBasedServicing
        SkipWindowsUpdate           = $SkipWindowsUpdate
        WindowsUpdate               = $windowsUpdate
        SkipPendingFileRename       = $SkipPendingFileRename
        PendingFileRename           = $pendingFileRename
        SkipPendingComputerRename   = $SkipPendingComputerRename
        PendingComputerRename       = $pendingComputerRename
        SkipCcmClientSDK            = $SkipCcmClientSDK
        CcmClientSDK                = $ccmClientSDK
    }
}

<#
    .SYNOPSIS
        Returns the current state of the pending reboot by assessing the result provided
        in a pending reboot hash table.

    .PARAMETER Name
        Specifies the name of this pending reboot check.

    .PARAMETER SkipComponentBasedServicing
        Specifies whether to skip reboots triggered by the Component-Based Servicing component.

    .PARAMETER SkipWindowsUpdate
        Specifies whether to skip reboots triggered by Windows Update.

    .PARAMETER SkipPendingFileRename
        Specifies whether to skip pending file rename reboots.

    .PARAMETER SkipPendingComputerRename
        Specifies whether to skip reboots triggered by a pending computer rename.

    .PARAMETER SkipCcmClientSDK
        Specifies whether to skip reboots triggered by the ConfigMgr client. Defaults to True.
#>
function Get-PendingRebootState
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.Boolean]
        $SkipComponentBasedServicing,

        [Parameter()]
        [System.Boolean]
        $SkipWindowsUpdate,

        [Parameter()]
        [System.Boolean]
        $SkipPendingFileRename,

        [Parameter()]
        [System.Boolean]
        $SkipPendingComputerRename,

        [Parameter()]
        [System.Boolean]
        $SkipCcmClientSDK = $true
    )

    $pendingRebootState = Get-PendingRebootHashTable @PSBoundParameters
    $rebootRequired = $false

    foreach ($rebootTrigger in $script:rebootTriggers)
    {
        $skipTriggerName = 'Skip{0}' -f $rebootTrigger.Name
        $skipTrigger = $pendingRebootState.$skipTriggerName

        if ($skipTrigger)
        {
            Write-Verbose -Message ($script:localizedData.RebootRequiredButSkippedMessage -f $rebootTrigger.Description)
        }
        else
        {
            if ($pendingRebootState.$($rebootTrigger.Name))
            {
                Write-Verbose -Message ($script:localizedData.RebootRequiredMessage -f $rebootTrigger.Description)
                $rebootRequired = $true
            }
            else
            {
                Write-Verbose -Message ($script:localizedData.RebootNotRequiredMessage -f $rebootTrigger.Description)
            }
        }
    }

    $pendingRebootState += @{
        RebootRequired = $rebootRequired
    }

    return $pendingRebootState
}

Export-ModuleMember -Function *-TargetResource
