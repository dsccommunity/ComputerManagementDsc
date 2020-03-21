<#PSScriptInfo
.VERSION 1.0.0
.GUID 10855e48-121b-455d-ac64-ff01e3a47eee
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
        This configuration will add the feature NetFx3 and use the folder
        'C:\Sources\sxs' for any needed files during install.
#>
Configuration DismFeature_AddFeatureWithSource_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        DismFeature 'NetFx3'
        {
            Ensure = 'Present'
            Name   = 'NetFx3'
            Source = 'C:\Sources\sxs'
        }
    }
}

