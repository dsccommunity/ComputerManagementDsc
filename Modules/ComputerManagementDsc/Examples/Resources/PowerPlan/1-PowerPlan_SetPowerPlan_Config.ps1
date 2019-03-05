<#PSScriptInfo
.VERSION 1.0.0
.GUID 547354f3-f5d1-4c76-8988-72887938e852
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
        This examples sets the active power plan to the 'High performance' plan.
#>
Configuration PowerPlan_SetPowerPlan_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        PowerPlan SetPlanHighPerformance
        {
          IsSingleInstance = 'Yes'
          Name             = 'High performance'
        }
    }
}
