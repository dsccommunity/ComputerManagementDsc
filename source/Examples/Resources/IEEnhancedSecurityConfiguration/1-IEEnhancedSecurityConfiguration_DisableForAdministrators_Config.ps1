<#PSScriptInfo
.VERSION 1.0.0
.GUID d54a9117-8468-4cb1-958b-25837f15126b
.AUTHOR DSC Community
.COMPANYNAME DSC Community
.COPYRIGHT DSC Community contributors. All rights reserved.
.TAGS DSCConfiguration
.LICENSEURI https://github.com/dsccommunity/ComputerManagementDsc/blob/main/LICENSE
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
        This configuration will disable the IE Enhanced Security Configuration for
        administrators.
#>
Configuration IEEnhancedSecurityConfiguration_DisableForAdministrators_Config
{
    Import-DscResource -Module ComputerManagementDsc

    Node localhost
    {
        IEEnhancedSecurityConfiguration 'DisableForAdministrators'
        {
            Role    = 'Administrators'
            Enabled = $false
        }
    }
}
