<#PSScriptInfo
.VERSION 1.0.0
.GUID 0d920405-2238-4ab5-871a-995e9baa0e28
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT (c) Microsoft Corporation. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/ComputerManagementDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/ComputerManagementDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>

#Requires -module ComputerManagementDsc

<#
    .DESCRIPTION
        This example sets the timezone of the node to Tonga Standard Time
        and then allows the LCM node to reboot the node only if System
        Center Configuration Manager requires a reboot. No other reboot
        trigger will cause the LCM to reboot the node.
#>
Configuration PendingReboot_ConfigMgrReboot_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        TimeZone TimeZoneExample
        {
            IsSingleInstance = 'Yes'
            TimeZone         = 'Tonga Standard Time'
        }

        PendingReboot ConfigMgrReboot
        {
            Name                        = 'ConfigMgr'
            SkipComponentBasedServicing = $true
            SkipWindowsUpdate           = $true
            SkipPendingFileRename       = $true
            SkipPendingComputerRename   = $true
            SkipCcmClientSDK            = $false
        }
    }
}
