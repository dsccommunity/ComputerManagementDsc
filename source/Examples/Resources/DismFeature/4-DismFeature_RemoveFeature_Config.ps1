<#PSScriptInfo
.VERSION 1.0.0
.GUID 51954b04-6ab9-4783-9784-0a3da5448f56
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT Copyright the DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ComputerManagementDsc/blob/master/LICENSE
.PROJECTURI https://github.com/dsccommunity/ComputerManagementDsc
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
        This configuration will remove the feature NetFx3.
#>
Configuration DismFeature_RemoveFeature_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        DismFeature 'RemoveNetFx3'
        {
            Ensure = 'Absent'
            Name   = 'NetFx3'
        }
    }
}
