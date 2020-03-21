<#PSScriptInfo
.VERSION 1.0.0
.GUID 7c386721-e20a-4f3e-abbe-68e4d1c036fc
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
        This configuration will add the feature IIS-HttpLogging and also install
        any parent features.
#>
Configuration DismFeature_AddFeatureIncludingParentFeatures_Config
{
    Import-DscResource -ModuleName ComputerManagementDsc

    Node localhost
    {
        DismFeature 'IIS-HttpLogging'
        {
            Ensure                  = 'Present'
            Name                    = 'IIS-HttpLogging'
            EnableAllParentFeatures = $true
        }
    }
}

